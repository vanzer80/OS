# 🤝 Guia de Contribuição - OS Express

Primeiramente, obrigado por considerar contribuir com o **OS Express**! 🎉

Este documento fornece diretrizes e informações sobre como contribuir para o projeto. Seguindo estas diretrizes, você ajuda a manter o projeto organizado e facilita a colaboração de todos.

## 📋 Índice

- [Como Contribuir](#como-contribuir)
- [Padrões de Desenvolvimento](#padrões-de-desenvolvimento)
- [Estrutura de Commits](#estrutura-de-commits)
- [Pull Requests](#pull-requests)
- [Relatórios de Bugs](#relatórios-de-bugs)
- [Sugestões de Features](#sugestões-de-features)
- [Ambiente de Desenvolvimento](#ambiente-de-desenvolvimento)
- [Testes](#testes)

## 🚀 Como Contribuir

### 1. **Fork o Projeto**
1. Acesse o repositório no GitHub
2. Clique em "Fork" no canto superior direito
3. Clone seu fork localmente:
   ```bash
   git clone https://github.com/seu-usuario/os-express-flutter.git
   cd os-express-flutter
   ```

### 2. **Configure o Upstream**
```bash
git remote add upstream https://github.com/usuario-original/os-express-flutter.git
```

### 3. **Crie uma Branch para sua Feature**
```bash
git checkout -b feature/nome-da-sua-feature
# ou
git checkout -b fix/nome-do-bug
# ou
git checkout -b docs/atualizacao-documentacao
```

### 4. **Faça suas Modificações**
- Mantenha o código limpo e seguindo os padrões
- Adicione testes se necessário
- Atualize a documentação se relevante

### 5. **Commit suas Mudanças**
```bash
git add .
git commit -m "feat: adicionar funcionalidade X"
```

### 6. **Push para seu Fork**
```bash
git push origin feature/nome-da-sua-feature
```

### 7. **Abra um Pull Request**
1. Vá para o repositório original no GitHub
2. Clique em "Compare & pull request"
3. Preencha o template com as informações necessárias
4. Clique em "Create pull request"

## 📝 Padrões de Desenvolvimento

### **Convenções de Código**
- **Dart/Flutter:** Siga as [diretrizes oficiais](https://dart.dev/guides/language/effective-dart)
- **Nomenclatura:** camelCase para variáveis, PascalCase para classes
- **Imports:** Organize por packages externos, depois relativos
- **Tamanho máximo:** 100 caracteres por linha

### **Estrutura de Pastas**
```
lib/
├── core/           # Serviços e configurações centrais
├── features/       # Funcionalidades por módulo
├── models/         # Modelos de dados
├── providers/      # Riverpod providers
├── utils/          # Utilitários e helpers
└── widgets/        # Widgets reutilizáveis
```

### **Estado e Gerenciamento**
- **Riverpod** para gerenciamento de estado
- **StateNotifier** para lógica complexa
- **StateProvider** para estados simples
- **FutureProvider** para dados assíncronos

### **Tratamento de Erros**
- Sempre trate erros em operações assíncronas
- Use `try/catch` para operações críticas
- Forneça feedback visual para o usuário
- Log erros importantes para debugging

## 📋 Estrutura de Commits

Use [Conventional Commits](https://conventionalcommits.org/) para mensagens consistentes:

```
tipo(escopo): descrição curta

corpo opcional

rodapé opcional
```

### **Tipos de Commit**
- `feat:` - Nova funcionalidade
- `fix:` - Correção de bug
- `docs:` - Documentação
- `style:` - Formatação (sem mudança funcional)
- `refactor:` - Refatoração de código
- `test:` - Testes
- `chore:` - Tarefas de manutenção

### **Exemplos**
```bash
feat: adicionar sistema de notificações push

fix: corrigir bug no upload de imagens

docs: atualizar README com novas instruções

refactor: otimizar queries do Supabase

test: adicionar testes para clientes service
```

## 🔄 Pull Requests

### **Template de PR**
Use este template ao criar um PR:

```markdown
## 📋 Descrição
[Breve descrição da mudança]

## 🎯 Tipo de Mudança
- [ ] 🐛 Bug fix
- [ ] ✨ Nova feature
- [ ] 📚 Documentação
- [ ] 🎨 Refatoração
- [ ] ✅ Testes
- [ ] 🔧 Configuração

## ✅ Checklist
- [ ] Código testado localmente
- [ ] Testes existentes passam
- [ ] Novos testes adicionados (se aplicável)
- [ ] Documentação atualizada (se aplicável)
- [ ] Sem conflitos de merge
- [ ] Commits seguem padrão conventional

## 🔗 Issues Relacionadas
- Closes #123
- Related to #456

## 📱 Screenshots (se aplicável)
[Adicione screenshots da mudança]

## 🧪 Como Testar
1. [Passo a passo para testar a mudança]
2. ...
```

### **Critérios de Aceitação**
- ✅ **Funcional:** A mudança funciona como esperado
- ✅ **Testada:** Coberta por testes (se aplicável)
- ✅ **Documentada:** README/atualizado se necessário
- ✅ **Revisada:** Pelo menos um approve de maintainer
- ✅ **CI/CD:** Todos os checks passam

## 🐛 Relatórios de Bugs

### **Antes de Reportar**
1. Verifique se já existe uma issue similar
2. Teste com a versão mais recente
3. Inclua informações do ambiente

### **Como Reportar**
1. Vá para a aba "Issues"
2. Clique em "New Issue"
3. Use o template de bug report
4. Preencha todas as informações solicitadas

### **Template de Bug Report**
```markdown
## 🐛 Descrição do Bug
[Descrição clara e concisa do bug]

## 📋 Passos para Reproduzir
1. [Primeiro passo]
2. [Segundo passo]
3. ...

## 🎯 Comportamento Esperado
[O que deveria acontecer]

## ❌ Comportamento Atual
[O que está acontecendo]

## 📱 Ambiente
- **Dispositivo:** [iOS/Android/Web/Desktop]
- **OS:** [Versão do sistema]
- **Flutter:** [Versão]
- **App Version:** [Versão do app]

## 📷 Screenshots
[Adicione screenshots se aplicável]

## 🔍 Logs
[Inclua logs relevantes]
```

## 💡 Sugestões de Features

### **Como Sugerir**
1. Verifique se já existe uma issue similar
2. Use o template de feature request
3. Seja específico sobre o problema que resolve
4. Considere alternativas e impactos

### **Template de Feature Request**
```markdown
## 💡 Descrição da Feature
[Descrição clara da nova funcionalidade]

## 🎯 Problema que Resolve
[Qual problema essa feature resolve?]

## 🔄 Solução Proposta
[Como você imagina que essa feature funcionaria?]

## 📋 Critérios de Aceitação
- [ ] [Critério 1]
- [ ] [Critério 2]
- [ ] ...

## 🔄 Alternativas Consideradas
[Outras soluções que você considerou]

## 📚 Referências
[Links para inspirações ou documentações]
```

## 🛠️ Ambiente de Desenvolvimento

### **Pré-requisitos**
- Flutter SDK 3.24.0+
- Dart 3.5.0+
- Conta Supabase
- Git

### **Setup Inicial**
```bash
# Clone o projeto
git clone https://github.com/seu-usuario/os-express-flutter.git
cd os-express-flutter

# Instale dependências
flutter pub get

# Configure Supabase
cp lib/core/supabase_config.example.dart lib/core/supabase_config.dart
# Edite com suas credenciais

# Execute
flutter run
```

### **Scripts Úteis**
```bash
# Limpar cache
flutter clean

# Gerar arquivos
flutter pub get

# Executar testes
flutter test

# Analisar código
flutter analyze

# Formatar código
flutter format lib/

# Build de produção
flutter build apk
```

## 🧪 Testes

### **Tipos de Teste**
- **Unit Tests:** Testes de funções isoladas
- **Widget Tests:** Testes de widgets
- **Integration Tests:** Testes de fluxos completos

### **Executar Testes**
```bash
# Todos os testes
flutter test

# Com coverage
flutter test --coverage

# Testes específicos
flutter test test/models/
```

### **Escrever Testes**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:os_express_flutter/models/client.dart';

void main() {
  group('Client Model', () {
    test('should create client from JSON', () {
      final json = {
        'id': '123',
        'name': 'João Silva',
        'email': 'joao@example.com',
      };

      final client = Client.fromJson(json);

      expect(client.id, '123');
      expect(client.name, 'João Silva');
      expect(client.email, 'joao@example.com');
    });
  });
}
```

## 📞 Contato e Suporte

- **Email:** zeus.ia010@gmail.com
- **Issues:** [GitHub Issues](https://github.com/usuario/os-express-flutter/issues)
- **Discussões:** [GitHub Discussions](https://github.com/usuario/os-express-flutter/discussions)

## 🎉 Reconhecimento

Agradecemos a todos os contribuidores! Sua ajuda é fundamental para o sucesso do OS Express.

---

**Este documento foi inspirado nas melhores práticas de projetos open source.**

*Última atualização: 24 de Setembro de 2024*
