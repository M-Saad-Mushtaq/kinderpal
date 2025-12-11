# Get Your Free Gemini API Key 🔑

## Quick Setup (2 minutes)

### Step 1: Get API Key
1. Go to: **https://makersuite.google.com/app/apikey**
2. Sign in with your Google account
3. Click **"Create API Key"** button
4. Copy the key (starts with `AIza...`)

### Step 2: Add to App
1. Open: `lib/services/ai_parser_service.dart`
2. Find line 14: `static const String geminiApiKey = '';`
3. Paste your key:
   ```dart
   static const String geminiApiKey = 'AIzaSy...YOUR_KEY_HERE';
   ```
4. Save the file

### Step 3: Done! 🎉
- Restart the app
- Try adding a rule like "Block Cocomelon channel"
- You'll see "Rule parsed and saved!" with the rule type

## What You Get (FREE)
- ✅ 15 requests per minute
- ✅ 1,500 requests per day
- ✅ Smart rule parsing
- ✅ No credit card needed

## Example Rules to Try
- "Block Cocomelon and Peppa Pig channels"
- "Limit YouTube to 2 hours daily"
- "No violent or scary content"
- "Only educational videos"
- "30 minutes on weekdays, 1 hour on weekends"

## Troubleshooting

**"Please set your Gemini API key":**
- Make sure you pasted the key correctly in ai_parser_service.dart
- Key should start with `AIza`
- Don't include any spaces or quotes (except the outer quotes)

**"API key not valid":**
- Regenerate key at https://makersuite.google.com/app/apikey
- Make sure you're using Gemini API, not other Google Cloud APIs

**Still not working?**
- Rules will save as simple text (still works, just not smart)
- You can manually manage rules without AI

## Why Gemini?
- **Free** - No payment needed
- **Easy** - Just one API key
- **Fast** - Cloud processing
- **Smart** - Understands natural language

No installation, no setup, just add your free key! 🚀
