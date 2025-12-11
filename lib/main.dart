import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
// import 'screens/email_verification_screen.dart'; // DISABLED: Email verification functionality
import 'screens/create_profile_screen.dart';
import 'screens/select_preferences_screen.dart';
import 'screens/custom_rules_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/guardian_dashboard_screen.dart';
import 'screens/youtube_history_screen.dart';
import 'screens/youtube_api_setup_screen.dart';
import 'screens/playlist_prompt_screen.dart';
import 'screens/generated_playlist_screen.dart';
import 'screens/profile_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Kinder Pal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          // '/email-verification': (context) => const EmailVerificationScreen(), // DISABLED: Email verification functionality
          '/youtube-api-setup': (context) => const YouTubeApiSetupScreen(),
          '/profile-selection': (context) => const ProfileSelectionScreen(),
          '/create-profile': (context) =>
              const CreateProfileScreen(isFromProfileTab: false),
          '/select-preferences': (context) => const SelectPreferencesScreen(),
          '/custom-rules': (context) => const CustomRulesScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/edit-profile': (context) => const EditProfileScreen(),
          '/guardian-dashboard': (context) => const GuardianDashboardScreen(),
          '/youtube-history': (context) => const YouTubeHistoryScreen(),
          '/playlist-prompt': (context) => const PlaylistPromptScreen(),
          '/generated-playlist': (context) => const GeneratedPlaylistScreen(),
        },
      ),
    );
  }
}
