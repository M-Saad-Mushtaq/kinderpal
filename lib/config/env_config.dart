class EnvConfig {
  const EnvConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.100.9:5000',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://qtuutontplzkqnsldmav.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF0dXV0b250cGx6a3Fuc2xkbWF2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjMyODY5NTIsImV4cCI6MjA3ODg2Mjk1Mn0.0UUbgnX28ucbm0Qzw-qwd795ds9G4kNC71k3eSwPVi0',
  );

  static const String youtubeApiKey = String.fromEnvironment(
    'YOUTUBE_API_KEY',
    defaultValue: 'AIzaSyCtkIGlgnAgU-5AyaaKEQG_AnEEOKLVIPw',
  );
//AIzaSyCXxSdotaK9WTpWJc9QPnyh77MBcVw6TL4
//AIzaSyCtkIGlgnAgU-5AyaaKEQG_AnEEOKLVIPw
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCHTfFSSAXEXIpWqa4jBEvpjf63AAsNHic',
  );

  static const String geminiUrl = String.fromEnvironment(
    'GEMINI_URL',
    defaultValue:
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent',
  );

  static const String ollamaUrl = String.fromEnvironment(
    'OLLAMA_URL',
    defaultValue: 'http://localhost:11434/api/chat',
  );
}