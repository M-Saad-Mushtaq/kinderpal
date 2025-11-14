import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/create_profile_screen.dart';
import 'screens/select_preferences_screen.dart';
import 'screens/custom_rules_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/guardian_dashboard_screen.dart';
import 'screens/playlist_prompt_screen.dart';
import 'screens/generated_playlist_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
    return MaterialApp(
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
        '/create-profile': (context) => const CreateProfileScreen(),
        '/select-preferences': (context) => const SelectPreferencesScreen(),
        '/custom-rules': (context) => const CustomRulesScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/guardian-dashboard': (context) => const GuardianDashboardScreen(),
        '/playlist-prompt': (context) => const PlaylistPromptScreen(),
        '/generated-playlist': (context) => const GeneratedPlaylistScreen(),
      },
    );
  }
}
