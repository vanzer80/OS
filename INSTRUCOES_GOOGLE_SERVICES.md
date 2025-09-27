# 🔧 CONFIGURAÇÃO COMPLETA - AUTENTICAÇÃO GOOGLE

## ⚠️ AÇÕES OBRIGATÓRIAS:

### 1. OBTER CLIENT IDs DO GOOGLE CLOUD CONSOLE
Acesse: https://console.cloud.google.com/apis/credentials

#### A. Client ID Web:
1. Encontre a credencial "Aplicativo da Web"
2. Copie o "ID do cliente" (termina com .apps.googleusercontent.com)
3. Anote para usar no passo 3

#### B. Client ID Android:
1. Encontre a credencial "Android"
2. Copie o "ID do cliente" (termina com .apps.googleusercontent.com)
3. Anote para usar no passo 3

### 2. BAIXAR google-services.json CORRETO
1. Na credencial Android, clique nos 3 pontos (...)
2. Selecione "Download JSON"
3. Substitua: `android/app/google-services.json`

### 3. CONFIGURAR CLIENT IDs NO CÓDIGO
Edite: `lib/core/supabase_config.dart`

```dart
// Substitua pelos seus Client IDs reais:
static const String googleWebClientId = 'SEU_WEB_CLIENT_ID.apps.googleusercontent.com';
static const String googleAndroidClientId = 'SEU_ANDROID_CLIENT_ID.apps.googleusercontent.com';
```

### 4. VERIFICAR SUPABASE DASHBOARD
1. Authentication > Providers > Google
2. Confirme que está ativado
3. Client ID deve ser o WEB Client ID
4. Client Secret deve estar preenchido

## ✅ APÓS CONFIGURAR:
```bash
flutter clean
flutter pub get
flutter run -d chrome  # Teste Web
flutter build apk --debug  # Teste Mobile
```
