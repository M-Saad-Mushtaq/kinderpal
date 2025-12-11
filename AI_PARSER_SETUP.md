# AI Rule Parsing - Free Options 🆓

## Overview
The custom rules system can parse natural language into structured rules using AI. You have **2 completely free options**:

## Option 1: Ollama (Local, Private, Free Forever) ✅ RECOMMENDED

**Best for:** Privacy, no internet required, unlimited usage

### What is Ollama?
- **100% FREE** and open source
- Runs **locally** on your computer (no data sent to cloud)
- **Unlimited usage** - no API limits
- Works **offline**
- Privacy-focused

### Setup Ollama:

1. **Download Ollama**: https://ollama.ai/download
   - Windows: Download installer
   - Mac: Download .app
   - Linux: `curl -fsSL https://ollama.ai/install.sh | sh`

2. **Install and run:**
   ```powershell
   # Download the model (one-time, ~1.5GB)
   ollama pull llama3.2
   
   # Verify it's working
   ollama list
   ```

3. **That's it!** Ollama runs automatically on `http://localhost:11434`

### Configuration:
The app is already configured to use Ollama by default:
```dart
// In custom_rules_screen.dart
final _aiService = AIParserService(useGemini: false); // false = Ollama
```

---

## Option 2: Google Gemini API (Cloud, Free Tier) ☁️

**Best for:** Can't install Ollama, want cloud processing

### What is Gemini API?
- **FREE tier**: 15 requests/minute, 1500 requests/day
- Cloud-based (requires internet)
- Fast and reliable
- By Google

### Setup Gemini:

1. **Get free API key:**
   - Go to: https://makersuite.google.com/app/apikey
   - Sign in with Google account
   - Click "Create API Key"
   - Copy the key

2. **Add key to app:**
   - Open `lib/services/ai_parser_service.dart`
   - Find line: `static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';`
   - Replace with your key: `static const String geminiApiKey = 'AIza...YOUR_KEY';`

3. **Enable Gemini in app:**
   - Open `lib/screens/custom_rules_screen.dart`
   - Change: `final _aiService = AIParserService(useGemini: true);`

---

## Comparison

| Feature | Ollama | Gemini API |
|---------|--------|------------|
| **Cost** | Free forever | Free tier (limits) |
| **Privacy** | 100% private (local) | Data sent to Google |
| **Setup** | Install software | Just API key |
| **Internet** | Not required | Required |
| **Speed** | Depends on PC | Fast (cloud) |
| **Limits** | Unlimited | 1500/day |
| **Size** | ~2GB download | None |

---

## How It Works

When you add a rule like:
```
"Block Cocomelon channel and limit to 2 hours daily"
```

The AI parses it into:
```json
{
  "rule_type": "mixed",
  "blocked_channels": ["Cocomelon"],
  "time_constraint": {
    "daily_limit": 120
  },
  "severity": "moderate"
}
```

This structured data enables:
- ✅ Actually blocking the channel
- ✅ Enforcing time limits
- ✅ Smart rule management

---

## Without AI (Fallback)

If neither AI is available, rules are saved as simple text:
```json
{
  "rule_type": "content_filter",
  "severity": "moderate"
}
```

You can still add/delete rules, but advanced features (channel blocking, time limits) won't work automatically.

---

## Troubleshooting

### Ollama Issues:

**"Ollama not available":**
```powershell
# Check if Ollama is running
ollama list

# Start Ollama service
ollama serve

# Test with a simple prompt
ollama run llama3.2 "test"
```

**Model not found:**
```powershell
# Pull the model again
ollama pull llama3.2
```

**Port conflict:**
- Ollama uses port 11434
- Check if another app is using it
- Change URL in `ai_parser_service.dart` if needed

### Gemini API Issues:

**"Please set your Gemini API key":**
- Add your real API key in `ai_parser_service.dart`
- Make sure it starts with `AIza...`

**Rate limit errors:**
- Free tier: 15 req/min, 1500 req/day
- Wait a minute and try again
- Consider using Ollama for unlimited usage

**Invalid API key:**
- Regenerate key at: https://makersuite.google.com/app/apikey
- Make sure API is enabled in Google Cloud Console

---

## Which Should I Use?

### Use Ollama if:
- ✅ You want complete privacy
- ✅ You have 2GB+ disk space
- ✅ You want unlimited usage
- ✅ You're okay installing software

### Use Gemini if:
- ✅ You can't install software
- ✅ You don't mind cloud processing
- ✅ You won't exceed 1500 rules/day
- ✅ You want quick setup

### Use Neither if:
- You only want basic rule text storage
- You'll manually enforce rules
- You want the simplest setup

---

## Testing

After setup, test by adding these rules in the app:

1. "Block Cocomelon channel"
   - Should detect: `rule_type: "channel_block"`
   - Should extract: `blocked_channels: ["Cocomelon"]`

2. "Limit to 2 hours daily"
   - Should detect: `rule_type: "time_limit"`
   - Should extract: `daily_limit: 120`

3. "No violent content"
   - Should detect: `rule_type: "content_filter"`
   - Should extract: `blocked_categories: ["violent"]`

Check the rule badge color to see if parsing worked!

---

## FAQ

**Q: Is Ollama really free?**
A: Yes! 100% free, open source, and runs on your computer.

**Q: Will Ollama slow down my PC?**
A: It only runs when parsing rules (a few seconds). Otherwise, no impact.

**Q: Is my data safe with Gemini?**
A: Google processes the text but doesn't store rule content. Check their privacy policy.

**Q: Can I switch between Ollama and Gemini?**
A: Yes! Just change `useGemini: true/false` in custom_rules_screen.dart

**Q: What if both fail?**
A: Rules save as simple text. You can manually enforce them.

**Q: How accurate is the AI?**
A: Very accurate for clear rules. Complex rules might need rephrasing.

---

## Recommended Setup

For best results:
1. Install **Ollama** for primary parsing (free, private, unlimited)
2. Add **Gemini** as backup (in case Ollama is down)
3. App automatically falls back if AI unavailable

Both are completely free! 🎉
