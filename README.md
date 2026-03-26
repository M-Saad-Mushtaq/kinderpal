# Kinder Pal - Safe and Smart Content for Kids 🎈

A Flutter app designed to provide safe, curated video content for children with parental controls and monitoring.

## Features ✨

- **User Authentication**: Login and Sign up functionality
- **Child Profile Management**: Create and manage child profiles
- **Content Preferences**: Select preferred categories for personalized content
- **Custom Rules**: Parents can set custom content filtering rules
- **Video Library**: Curated videos organized by categories (Art, Music, Science, Sports)
- **AI Playlist Generation**: Generate playlists using text prompts
- **Parental Dashboard**: Monitor screen time, last watched content, and alerts
- **Profile Management**: Edit child information and preferences

## Project Structure 📁

```
lib/
├── constants/
│   ├── app_colors.dart        # Color palette
│   └── app_text_styles.dart   # Typography styles
├── widgets/
│   ├── custom_button.dart     # Reusable button component
│   ├── custom_text_field.dart # Reusable input field
│   ├── category_card.dart     # Category selection card
│   ├── rule_chip.dart         # Custom rule chip
│   └── bottom_nav_bar.dart    # Bottom navigation
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── create_profile_screen.dart
│   ├── select_preferences_screen.dart
│   ├── custom_rules_screen.dart
│   ├── home_screen.dart
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   ├── guardian_dashboard_screen.dart
│   ├── playlist_prompt_screen.dart
│   └── generated_playlist_screen.dart
└── main.dart                  # App entry point with routing
```

## Navigation Flow 🔄

### First Time User (Sign Up)
1. Splash Screen → Sign Up
2. Create Child Profile
3. Select Preferences
4. Custom Rules
5. Home Screen

### Returning User (Login)
1. Splash Screen → Login
2. Home Screen

### Main Navigation
- **Home Tab**: Browse videos by category
- **Playlist Tab**: Generate AI playlists
- **Profile Tab**: Access settings and dashboard
  - Parental Dashboard
  - Select Preferences
  - Edit Info

## Running the App 🚀

```bash
# Get dependencies
flutter pub get

# Run on your device/emulator
flutter run
```

### Environment Configuration (Required) 🔐

Sensitive keys are read from `--dart-define` values.

Required defines:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `YOUTUBE_API_KEY`
- `GEMINI_API_KEY` (only if using Gemini parser)
- `API_BASE_URL` (example: `http://10.0.2.2:5000` on Android emulator)

Optional defines:

- `OLLAMA_URL` (default: `http://localhost:11434/api/chat`)
- `GEMINI_URL` (defaults to Gemini generateContent endpoint)

Example:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key \
  --dart-define=YOUTUBE_API_KEY=your_youtube_api_key \
  --dart-define=GEMINI_API_KEY=your_gemini_api_key \
  --dart-define=API_BASE_URL=http://10.0.2.2:5000
```

Or use a JSON file (recommended):

```bash
cp env.example.json env.json
# fill env.json with real values
flutter run --dart-define-from-file=env.json
```

## Color Palette 🎨

- **Primary**: Purple (#8B7FFF)
- **Light Blue**: #B3D9FF
- **Beige**: #FFF8E8
- **Accent Colors**: Red, Yellow, Green, Pink, Peach, Cyan

## Dependencies 📦

- `google_fonts`: Custom fonts
- `cupertino_icons`: iOS-style icons

## Next Steps (Backend Integration) 🔮

- User authentication with Firebase/Backend
- Video content API integration
- AI playlist generation API
- Parental controls backend
- Screen time tracking
- Real-time alerts system

---

Built with ❤️ using Flutter

