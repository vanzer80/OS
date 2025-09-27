# ⚠️ AÇÃO NECESSÁRIA: CORRIGIR google-services.json

## PROBLEMA ATUAL:
O arquivo `android/app/google-services.json` está INCORRETO!
Atualmente contém credenciais Desktop/Web, mas precisa ser Android.

## SOLUÇÃO:
1. Acesse: https://console.cloud.google.com/apis/credentials
2. Encontre a credencial Android que você criou
3. Clique nos 3 pontos (...) ao lado da credencial Android
4. Selecione "Download JSON"
5. Substitua o arquivo em: `android/app/google-services.json`

## O QUE PROCURAR NO ARQUIVO CORRETO:
```json
{
  "project_info": {
    "project_number": "...",
    "project_id": "os-express-app"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:...:android:...",
        "android_client_info": {
          "package_name": "com.osexpresss.app.os_express_flutter"
        }
      }
    }
  ]
}
```

## APÓS CORRIGIR:
Execute: `flutter clean && flutter build apk --debug`
