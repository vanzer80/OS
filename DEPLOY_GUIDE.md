# 🚀 Guia de Deploy - OS Express na Vercel

## 📋 Instruções para Deploy

### 1. Pré-requisitos
- Conta na [Vercel](https://vercel.com)
- Repositório Git com o código do projeto
- Flutter SDK instalado (para desenvolvimento local)

### 2. Configuração do Deploy na Vercel

#### Passo 1: Conectar Repositório
1. Acesse [vercel.com](https://vercel.com) e faça login
2. Clique em "New Project"
3. Conecte seu repositório GitHub/GitLab/Bitbucket
4. Selecione o repositório do OS Express

#### Passo 2: Configurar Variáveis de Ambiente
Na seção "Environment Variables" da Vercel, adicione:

```
SUPABASE_URL=https://bbgisqfuuldolqiclupu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJiZ2lzcWZ1dWxkb2xxaWNsdXB1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg3NTgwNTYsImV4cCI6MjA3NDMzNDA1Nn0.Z9YwdNQQZPXG5hfs9WUYUrwwNbA-KXYgHQo7KErHtQ8
GOOGLE_WEB_CLIENT_ID=77408990333-dn38l5utt4f2artjn27o0kdfqtgq3cvd.apps.googleusercontent.com
FLUTTER_WEB=true
NODE_ENV=production
```

#### Passo 3: Deploy
1. Clique em "Deploy"
2. Aguarde o processo de build (aproximadamente 2-3 minutos)
3. Acesse a URL gerada pela Vercel

### 3. Configurações Adicionais

#### Domínio Personalizado (Opcional)
1. Na dashboard do projeto na Vercel
2. Vá para "Settings" > "Domains"
3. Adicione seu domínio personalizado

#### Configurações de Segurança
O projeto já inclui headers de segurança configurados no `vercel.json`:
- Content Security Policy
- X-Frame-Options
- X-XSS-Protection
- Referrer Policy

---

## 👥 Instruções para Usuários Testadores

### 🌐 URL do Aplicativo
**URL de Produção:** [https://os-express.vercel.app](https://os-express.vercel.app)
*(Substitua pela URL real gerada pela Vercel)*

### 💻 Requisitos Mínimos do Sistema

#### Navegadores Suportados
- **Chrome:** Versão 88+ (Recomendado)
- **Firefox:** Versão 85+
- **Safari:** Versão 14+
- **Edge:** Versão 88+

#### Dispositivos
- **Desktop:** Windows 10+, macOS 10.15+, Linux (Ubuntu 18.04+)
- **Mobile:** iOS 12+, Android 8.0+
- **Resolução mínima:** 1024x768 (desktop), 375x667 (mobile)

#### Conectividade
- Conexão com internet estável
- Velocidade mínima recomendada: 1 Mbps

### 🚀 Como Usar o Sistema

#### 1. Primeiro Acesso
1. Acesse a URL do aplicativo
2. Clique em "Entrar com Google" para fazer login
3. Autorize o acesso às suas informações básicas
4. Complete seu perfil da empresa na primeira tela

#### 2. Funcionalidades Principais

##### 📊 Dashboard
- Visão geral das ordens de serviço
- Estatísticas de vendas e pagamentos
- Acesso rápido às funcionalidades

##### 👥 Gestão de Clientes
- Cadastrar novos clientes
- Editar informações existentes
- Visualizar histórico de ordens

##### 📋 Ordens de Serviço
- Criar novas ordens
- Adicionar itens e serviços
- Anexar fotos e documentos
- Controlar status (Pendente → Em Andamento → Concluída)

##### 💰 Financeiro
- Registrar pagamentos
- Gerar relatórios
- Controlar fluxo de caixa

##### 🧾 Geração de PDFs
- Orçamentos profissionais
- Recibos de pagamento
- Relatórios personalizados

#### 3. Dicas de Uso
- Use o menu lateral para navegar entre seções
- Todas as alterações são salvas automaticamente
- As imagens são armazenadas na nuvem com segurança
- O sistema funciona offline para consultas básicas

### 🐛 Como Reportar Problemas

#### Formulário de Feedback
**Link:** [https://forms.google.com/feedback-os-express](https://forms.google.com/feedback-os-express)
*(Substitua pelo link real do formulário)*

#### Informações Necessárias
Ao reportar um problema, inclua:

1. **Navegador e versão** (ex: Chrome 120.0)
2. **Sistema operacional** (ex: Windows 11, macOS Sonoma)
3. **Dispositivo** (Desktop/Mobile/Tablet)
4. **Descrição detalhada** do problema
5. **Passos para reproduzir** o erro
6. **Screenshots** (se aplicável)
7. **Mensagens de erro** (se houver)

#### Canais de Suporte
- **Email:** suporte@osexpresss.com
- **WhatsApp:** +55 (11) 99999-9999
- **Telegram:** @osexpresss_suporte

### 📊 Métricas de Teste

Durante o período de testes, monitoraremos:
- **Performance:** Tempo de carregamento das páginas
- **Usabilidade:** Facilidade de navegação
- **Estabilidade:** Frequência de erros
- **Compatibilidade:** Funcionamento em diferentes dispositivos

### 🎯 Objetivos do Teste
- Validar todas as funcionalidades principais
- Identificar problemas de usabilidade
- Testar performance em diferentes dispositivos
- Coletar feedback para melhorias

### ⏰ Período de Testes
- **Início:** [Data de início]
- **Duração:** 2 semanas
- **Feedback até:** [Data limite]

---

## 🔧 Solução de Problemas Comuns

### Problema: Página não carrega
**Solução:**
1. Verifique sua conexão com internet
2. Limpe o cache do navegador (Ctrl+Shift+Delete)
3. Tente em modo anônimo/privado
4. Atualize a página (F5)

### Problema: Login não funciona
**Solução:**
1. Verifique se está usando uma conta Google válida
2. Desabilite bloqueadores de pop-up
3. Limpe cookies do site
4. Tente em outro navegador

### Problema: Imagens não aparecem
**Solução:**
1. Verifique sua conexão com internet
2. Aguarde alguns segundos para carregamento
3. Atualize a página
4. Verifique se o formato da imagem é suportado (JPG, PNG, WebP)

### Problema: Sistema lento
**Solução:**
1. Feche outras abas do navegador
2. Verifique se há atualizações do navegador
3. Reinicie o navegador
4. Teste em horários de menor tráfego

---

## 📞 Contato e Suporte

Para dúvidas técnicas ou suporte durante o deploy:
- **Email:** dev@osexpresss.com
- **GitHub Issues:** [Link do repositório]
- **Documentação:** [Link da documentação técnica]

---

*Última atualização: Janeiro 2025*