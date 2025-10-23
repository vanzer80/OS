class SupabaseConfig {
  static const String supabaseUrl = 'https://bbgisqfuuldolqiclupu.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJiZ2lzcWZ1dWxkb2xxaWNsdXB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NTgwNTYsImV4cCI6MjA3NDMzNDA1Nn0.Z9YwdNQQZPXG5hfs9WUYUrwwNbA-KXYgHQo7KErHtQ8';

  // Configurações do projeto
  static const String projectName = 'OS Express';
  static const String projectVersion = '1.0.0';

  // Configurações de storage para imagens
  static const String imagesBucket = 'order-images';
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];
  static const int maxImagesPerOrder = 5;

  // Configurações Google OAuth
  static const String googleWebClientId =
      '77408990333-dn38l5utt4f2artjn27o0kdfqtgq3cvd.apps.googleusercontent.com';
  static const String googleAndroidClientId =
      '77408990333-up512fsnj0tdmk9ru2osev3utn39o6p0.apps.googleusercontent.com';

  // URLs de redirecionamento
  static String get authCallbackUrl => '$supabaseUrl/auth/v1/callback';
}
