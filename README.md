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

