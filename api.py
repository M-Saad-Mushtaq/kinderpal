from flask import Flask, request, jsonify
import torch
import torch.nn as nn
from torchvision import transforms, models
from transformers import DistilBertTokenizer, DistilBertModel
from PIL import Image
import io
import base64
import re

app = Flask(__name__)


class MultimodalClassifier(nn.Module):
    def __init__(self, num_classes):
        super(MultimodalClassifier, self).__init__()
        self.bert = DistilBertModel.from_pretrained('distilbert-base-multilingual-cased')
        self.text_drop = nn.Dropout(0.5)
        self.resnet = models.resnet50(weights=models.ResNet50_Weights.IMAGENET1K_V1)
        self.resnet.fc = nn.Identity()
        self.fusion = nn.Sequential(
            nn.Linear(2816, 512),
            nn.BatchNorm1d(512),
            nn.ReLU(),
            nn.Dropout(0.5),
            nn.Linear(512, num_classes)
        )

    def forward(self, input_ids, attention_mask, images):
        text_out = self.bert(input_ids=input_ids, attention_mask=attention_mask)[0]
        text_vec = self.text_drop(text_out[:, 0, :])
        img_vec = self.resnet(images)
        combined = torch.cat((text_vec, img_vec), dim=1)
        return self.fusion(combined)

# Load checkpoint
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
checkpoint = torch.load("best_model.pth", map_location=DEVICE,weights_only=False)
label_classes = checkpoint['label_classes']
num_classes = len(label_classes)

model = MultimodalClassifier(num_classes)
model.load_state_dict(checkpoint['model_state_dict'])
model.to(DEVICE)
model.eval()

tokenizer = DistilBertTokenizer.from_pretrained('distilbert-base-multilingual-cased')

transform = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

def clean_text(text):
    text = str(text)
    text = re.sub(r'\s+', ' ', text).strip()
    return text

@app.route('/classify', methods=['POST'])
def classify():
    data = request.json
    title = data.get('title', '')
    thumbnail_b64 = data.get('thumbnail_base64', '')

    # Process text
    text = clean_text(title)
    inputs = tokenizer(
        text,
        add_special_tokens=True,
        max_length=64,
        padding='max_length',
        truncation=True,
        return_tensors='pt'
    )

    # Process image
    try:
        img_bytes = base64.b64decode(thumbnail_b64)
        image = Image.open(io.BytesIO(img_bytes)).convert("RGB")
    except:
        image = Image.new('RGB', (224, 224), color='black')

    image = transform(image).unsqueeze(0)

    # Predict
    with torch.no_grad():
        input_ids = inputs['input_ids'].to(DEVICE)
        mask = inputs['attention_mask'].to(DEVICE)
        image = image.to(DEVICE)
        outputs = model(input_ids, mask, image)
        _, predicted = torch.max(outputs, 1)
        predicted_class = label_classes[predicted.item()]

    return jsonify({'predicted_class': predicted_class})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)