# 🚀 OS Express - Sistema de Ordens de Serviço

[![Flutter](https://img.shields.io/badge/Flutter-3.24.0-blue.svg)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-2.8.0-3ECF8E.svg)](https://supabase.com)
[![Dart](https://img.shields.io/badge/Dart-3.5.0-0175C2.svg)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Sistema completo para gestão de ordens de serviço, orçamentos e vendas para oficinas mecânicas e prestadores de serviços.

## 📋 Sobre o Projeto

**OS Express** é uma aplicação móvel desenvolvida em Flutter para modernizar a gestão de oficinas mecânicas e prestadores de serviços. O sistema permite criar ordens de serviço, orçamentos e vendas de forma digital, com integração completa ao Supabase para armazenamento seguro e em tempo real.

### 🎯 Objetivo
Substituir os tradicionais blocos de papel por uma solução digital completa, oferecendo:
- Cadastro digital de clientes
- Geração automática de ordens numeradas
- Controle de itens e valores
- Anexo de até 5 imagens por ordem
- Exportação para PDF e WhatsApp
- Modo escuro para melhor usabilidade

## 🏗️ Arquitetura e Stack Tecnológica

### Frontend (Flutter)
- **Framework:** Flutter 3.24.0
- **Linguagem:** Dart 3.5.0
- **State Management:** Riverpod 2.6.1
- **Navegação:** Go Router 14.6.2
- **UI Components:** Material Design 3

### Backend e Banco de Dados
- **Backend as a Service:** Supabase 2.8.0
- **Banco de Dados:** PostgreSQL
- **Autenticação:** Supabase Auth
- **Storage:** Supabase Storage (imagens)
- **Segurança:** Row Level Security (RLS)

### Dependências Principais
```yaml
# Core
flutter_riverpod: ^2.6.1          # Gerenciamento de estado
go_router: ^14.6.2               # Navegação

# Backend
supabase_flutter: ^2.8.0         # Integração Supabase

# Autenticação
google_sign_in: ^6.2.1           # Login Google

# Utilitários
image_picker: ^1.1.2             # Seleção de imagens
permission_handler: ^11.3.1       # Permissões
pdf: ^3.11.1                     # Geração de PDF
printing: ^5.13.4                # Impressão
path_provider: ^2.1.4            # Gerenciamento de arquivos
share_plus: ^10.1.1              # Compartilhamento
url_launcher: ^6.3.1             # Abertura de URLs
intl: ^0.18.1                    # Internacionalização
uuid: ^4.5.1                     # Geração de IDs
```

## 🗄️ Estrutura do Banco de Dados

### Tabelas Principais

#### 1. `clients` - Cadastro de Clientes
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key → auth.users)
- name: VARCHAR(255) - Nome completo *
- email: VARCHAR(255) - Email opcional
- phone: VARCHAR(50) - Telefone opcional
- address: TEXT - Endereço completo
- document: VARCHAR(50) - CPF/CNPJ
- notes: TEXT - Observações
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### 2. `service_orders` - Ordens de Serviço
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key → auth.users)
- client_id: UUID (Foreign Key → clients)
- order_number: VARCHAR(50) - Número único (OS-001, OS-002...)
- type: ENUM('service', 'budget', 'sale')
- status: ENUM('pending', 'in_progress', 'completed', 'cancelled')
- equipment: VARCHAR(255) - Equipamento/Marca
- model: VARCHAR(255) - Modelo
- description: TEXT - Descrição do serviço
- total_amount: DECIMAL(10,2) - Valor total
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### 3. `order_items` - Itens das Ordens
```sql
- id: UUID (Primary Key)
- order_id: UUID (Foreign Key → service_orders)
- description: VARCHAR(255) - Descrição do item
- quantity: INTEGER - Quantidade
- unit_price: DECIMAL(10,2) - Preço unitário
- total_price: DECIMAL(10,2) - Preço total (auto-calculado)
- created_at: TIMESTAMP
```

#### 4. `order_attachments` - Anexos/Imagens
```sql
- id: UUID (Primary Key)
- order_id: UUID (Foreign Key → service_orders)
- file_name: VARCHAR(255) - Nome do arquivo
- file_path: VARCHAR(500) - Caminho no storage
- file_type: VARCHAR(50) - Tipo do arquivo
- file_size: INTEGER - Tamanho em bytes
- created_at: TIMESTAMP
```

#### 5. `user_settings` - Configurações do Usuário
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key → auth.users)
- company_name: VARCHAR(255) - Nome da empresa
- company_document: VARCHAR(50) - CNPJ
- company_address: TEXT - Endereço da empresa
- company_phone: VARCHAR(50) - Telefone da empresa
- company_email: VARCHAR(255) - Email da empresa
- logo_url: VARCHAR(500) - URL do logo
- theme_mode: ENUM('light', 'dark', 'system')
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

### 🔐 Segurança (Row Level Security)
- Todas as tabelas possuem RLS habilitado
- Usuários só acessam seus próprios dados
- Políticas específicas para cada operação (SELECT, INSERT, UPDATE, DELETE)

## 🚀 Funcionalidades Implementadas

### ✅ **MVP - Funcionalidades Essenciais**

#### 1. Autenticação e Usuários
- [x] Login com email/senha
- [x] Cadastro de novos usuários
- [x] Login com Google (preparado)
- [x] Persistência de sessão
- [x] Logout seguro

#### 2. Gestão de Clientes
- [x] Cadastro completo de clientes
- [x] Lista com busca em tempo real
- [x] Edição de clientes existentes
- [x] Exclusão com confirmação
- [x] Validação de dados
- [x] Importação de contatos (preparado)

#### 3. Ordens de Serviço
- [x] Criação de ordens (3 tipos: serviço, orçamento, venda)
- [x] Numeração automática (OS-001, OS-002...)
- [x] Associação com clientes
- [x] Controle de status
- [x] Cálculo automático de totais

#### 4. Itens das Ordens
- [x] Adição de múltiplos itens
- [x] Cálculo automático de valores
- [x] Quantidade e preços unitários
- [x] Soma automática do total da ordem

#### 5. Anexos e Imagens
- [x] Upload de até 5 imagens por ordem
- [x] Câmera e galeria
- [x] Storage seguro no Supabase
- [x] Limite de 5MB por imagem
- [x] Tipos suportados: JPG, PNG, WebP

#### 6. Interface e UX
- [x] Design moderno (Material Design 3)
- [x] Modo escuro automático
- [x] Navegação por abas
- [x] Loading states e tratamento de erros
- [x] Pull-to-refresh
- [x] Confirmações de ações críticas

### 🔄 **Funcionalidades em Desenvolvimento**

#### 7. Geração de PDF
- [x] Layout profissional para ordens
- [x] Inclusão de logo da empresa (quando configurado)
- [x] Dados do cliente, equipamento, itens e totais
- [x] Seção "Fotos" no final com 3 colunas
- [x] Títulos e descrições por imagem no PDF
- [x] Fonte NotoSans embutida com `fontFallback` (Unicode seguro, sem warnings)

#### 8. Exportação e Compartilhamento
- [x] Visualizar/baixar PDF
- [x] Compartilhar PDF (Share Sheet do sistema)
- [ ] Compartilhar direto no WhatsApp (atalho dedicado)
- [ ] Envio por email com template
- [ ] Impressão direta (integração avançada)
- [ ] Histórico de exportações

#### 9. Configurações Avançadas
- [ ] Configurações da empresa
- [ ] Personalização de tema
- [ ] Backup e sincronização
- [ ] Notificações push

#### 10. Recursos Avançados
- [ ] OCR para leitura de documentos
- [ ] IA para sugestões de preços
- [ ] Integração com sistemas fiscais
- [ ] Relatórios e analytics

## 📁 Estrutura do Projeto

```
lib/
├── core/                          # Serviços e configurações centrais
│   ├── supabase_config.dart      # Configurações do Supabase
│   ├── supabase_auth_service.dart # Serviço de autenticação
│   ├── clients_service.dart      # Serviço de clientes
│   └── orders_service.dart       # Serviço de ordens (próximo)
├── features/                      # Funcionalidades por módulo
│   ├── auth/                     # Autenticação
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── auth_state.dart
│   ├── dashboard/                # Dashboard principal
│   │   └── dashboard_screen.dart
│   ├── clients/                  # Gestão de clientes
│   │   ├── add_client_screen.dart
│   │   └── client_details_screen.dart
│   ├── orders/                   # Ordens de serviço
│   │   ├── add_order_screen.dart
│   │   ├── order_details_screen.dart
│   │   └── order_items_screen.dart
│   └── settings/                 # Configurações
│       └── settings_screen.dart
├── models/                       # Modelos de dados
│   ├── client.dart
│   ├── service_order.dart
│   ├── order_item.dart
│   └── user_settings.dart
├── providers/                    # Providers Riverpod
│   ├── auth_provider.dart
│   ├── clients_provider.dart
│   └── orders_provider.dart
├── utils/                        # Utilitários
│   ├── constants.dart
│   ├── helpers.dart
│   └── validators.dart
└── widgets/                      # Widgets reutilizáveis
    ├── custom_button.dart
    ├── loading_indicator.dart
    └── error_display.dart
```

## 🛠️ Configuração e Instalação

### Pré-requisitos

1. **Flutter SDK 3.24.0+**
   ```bash
   flutter --version
   ```

2. **Dart SDK 3.5.0+**
   ```bash
   dart --version
   ```

3. **Conta Supabase**
   - Projeto criado: `OS Express - Sistema de Ordens de Serviço`
   - URL: `https://bbgisqfuuldolqiclupu.supabase.co`
   - Organização: `os` (zeus.ia010@gmail.com)

### 1. Clone o Repositório
```bash
git clone https://github.com/seu-usuario/os-express-flutter.git
cd os-express-flutter
```

### 2. Instale as Dependências
```bash
flutter pub get
```

### 3. Configure o Supabase
```bash
# Edite o arquivo lib/core/supabase_config.dart
const supabaseUrl = 'https://bbgisqfuuldolqiclupu.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';
```

### 4. Execute o Projeto
```bash
# Desktop (Chrome)
flutter run -d chrome

# Android
flutter run -d android

# iOS
flutter run -d ios

# Windows
flutter run -d windows
```

## 🧪 Como Testar

### 1. Criar Conta
1. Abra o app
2. Clique em "Criar Conta"
3. Preencha email e senha
4. Confirme o email (se necessário)

### 2. Cadastrar Cliente
1. Faça login
2. Vá para aba "Clientes"
3. Clique no botão "+"
4. Preencha os dados do cliente
5. Salve

### 3. Criar Ordem de Serviço
1. Vá para aba "Ordens"
2. Clique em "Nova Ordem"
3. Selecione tipo (Serviço/Orçamento/Venda)
4. Escolha um cliente
5. Adicione itens com quantidades e preços
6. Anexe imagens (opcional)
7. Salve a ordem

### 4. Buscar e Editar
1. Use a busca para encontrar clientes/ordens
2. Clique nos itens para editar
3. Use os menus de contexto (3 pontos)

## 🔧 Desenvolvimento

### Adicionar Nova Dependência
```bash
flutter pub add nome_da_dependencia
```

### Gerar Arquivos Necessários
```bash
# Limpar cache
flutter clean

# Gerar arquivos
flutter pub get

# Se necessário
flutter pub run build_runner build
```

### Executar Testes
```bash
flutter test
```

### Build de Produção
```bash
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS
flutter build ios

# Web
flutter build web
```

## 📱 Deploy e Distribuição

### Android
1. Configure o `android/key.properties`
2. Execute `flutter build appbundle`
3. Faça upload para Google Play Console

### iOS
1. Configure o `ios/Runner/Info.plist`
2. Execute `flutter build ios`
3. Faça upload para App Store Connect

### Web
1. Execute `flutter build web`
2. Deploy recomendado: Cloudflare Pages (grátis, rápido) ou Netlify/Vercel/Firebase Hosting
3. Subdomínio no Cloudflare (`app.seudominio.com`) via CNAME para Pages

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 Suporte e Contato

- **Email:** zeus.ia010@gmail.com
- **Projeto Supabase:** https://supabase.com/dashboard/project/bbgisqfuuldolqiclupu
- **Documentação Supabase:** https://supabase.com/docs

## 🎯 Roadmap

### Sprint 1 (Atual) ✅
- [x] Configuração inicial Flutter + Supabase
- [x] Sistema de autenticação
- [x] CRUD de clientes
- [x] Estrutura base do banco de dados

### Sprint 2 (Em Andamento)
- [x] CRUD de ordens de serviço
- [x] Sistema de itens com auto-soma
- [x] Upload de imagens
- [ ] Geração de PDF

### Sprint 3 (Próximo)
- [ ] Export PDF + WhatsApp
- [ ] Configurações da empresa
- [ ] Relatórios básicos
- [ ] Melhorias na UI/UX

### Sprint 4 (Futuro)
- [ ] OCR para documentos
- [ ] IA para sugestões
- [ ] Integração fiscal
- [ ] API para sistemas externos

## 💡 Dicas para Desenvolvimento

1. **Use sempre Riverpod** para gerenciar estado
2. **Teste no Supabase** antes de implementar no Flutter
3. **Siga as convenções** de nomenclatura do Dart
4. **Documente** funções e classes importantes
5. **Use constantes** para valores fixos
6. **Trate erros** adequadamente em todas as operações
7. **Teste em múltiplos dispositivos** antes do deploy

---

**Desenvolvido com ❤️ para modernizar oficinas mecânicas e prestadores de serviços.**

*Última atualização: 27 de Setembro de 2025*
