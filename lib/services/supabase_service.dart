import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://qtuutontplzkqnsldmav.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0dXV0b250cGx6a3Fuc2xkbWF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyODY5NTIsImV4cCI6MjA3ODg2Mjk1Mn0.0UUbgnX28ucbm0Qzw-qwd795ds9G4kNC71k3eSwPVi0';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    debugPrint('Supabase initialized successfully');
  }

  static SupabaseClient get client => Supabase.instance.client;
}
