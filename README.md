# **CSI606-2024-02 - Remoto - Trabalho Final - Resultados**

## *Discente: Igor Marques Passos (22.2.8118)*

### Resumo

O trabalho final apresenta o desenvolvimento de um Sistema de Gerenciamento de Relatórios de Inspeção de Carga (TCIS), uma aplicação mobile multiplataforma desenvolvida em Flutter com backend Node.js. O sistema permite o gerenciamento completo de relatórios de inspeção, incluindo criação, edição, visualização e administração de dados relacionados como usuários, terminais, produtos e fornecedores. A aplicação oferece funcionalidades offline para criação de relatórios e sincronização automática quando há conexão disponível, atendendo às necessidades de inspetores de carga em terminais portuários e ferroviários.

## 1. Funcionalidades implementadas

### 1.1 Sistema Mobile (Flutter)
- **Autenticação de usuários** com sistema de roles (USER/ADMIN)
- **Criação completa de relatórios de inspeção** incluindo:
  - Seleção de terminal, produto e fornecedor
  - Registro de dados de chegada/saída e tipo de vagão
  - Condições da carga (contaminação, umidade, chuva)
  - Captura e anexo de múltiplas imagens
  - Observações detalhadas e comentários
- **Visualização e edição** de relatórios existentes
- **Sistema de navegação** intuitivo com Bottom Navigation
- **Gerenciamento de perfil** do usuário
- **Interface responsiva** com Material Design

### 1.2 Painel Administrativo
- **Dashboard administrativo** com visão geral do sistema
- **Gerenciamento completo de usuários** (criação, edição, ativação/desativação)
- **Cadastro e gestão de terminais** com códigos e prefixos
- **Controle de produtos** e códigos identificadores
- **Gestão de fornecedores** e informações corporativas
- **Gestão de clientes** do sistema
- **Visualização de todos os relatórios** com filtros avançados

### 1.3 Backend e API (Node.js/Express)
- **API RESTful completa** para todas as operações CRUD
- **Banco de dados PostgreSQL** com Prisma ORM
- **Sistema de autenticação JWT** com controle de sessões
- **Upload e gerenciamento de imagens** com validação
- **Controle de acesso baseado em roles** (USER/ADMIN)
- **Validação robusta** de dados e relacionamentos
- **Middleware de segurança** e tratamento de erros
- **Sistema de logs** e monitoramento

### 1.4 Infraestrutura e Deploy
- **Containerização Docker** completa
- **Docker Compose** para ambiente de desenvolvimento
- **Scripts de deploy** automatizados
- **Configuração Nginx** para proxy reverso
- **Suporte a HTTPS** e certificados SSL

## 2. Funcionalidades previstas e não implementadas

- **Modo offline completo** - Implementação parcial (estrutura preparada mas não finalizada)
- **Sincronização automática** - Backend preparado mas sincronização não implementada
- **Sistema de filtros avançados** nos relatórios móveis
- **Notificações push** em tempo real
- **Backup automático** em nuvem
- **Relatórios analíticos** com gráficos e estatísticas

## 3. Outras funcionalidades implementadas

Além das funcionalidades inicialmente previstas, foram implementadas:

- **Sistema de gerenciamento de clientes** (funcionalidade adicional)
- **Interface web administrativa** completa
- **Sistema de logs detalhado** no backend
- **Validação de imagens** com controle de tamanho e formato
- **Sistema de prefixos automáticos** para relatórios
- **Middleware de compressão** para otimização
- **Tratamento robusto de erros** em toda aplicação
- **Scripts de manutenção** e utilitários
- **Documentação técnica** detalhada de deploy

## 4. Principais desafios e dificuldades

### 4.1 Desafios Técnicos
- **Gerenciamento de Estado no Flutter**: Implementação da arquitetura Provider para estado global
- **Upload de Imagens**: Configuração correta do sistema de upload com validação e otimização
- **Relacionamentos Complexos**: Modelagem e implementação de relacionamentos entre entidades no Prisma
- **Autenticação JWT**: Implementação segura com renovação de tokens e middleware

### 4.2 Desafios de Infraestrutura
- **Containerização**: Configuração otimizada do Docker para desenvolvimento e produção
- **Proxy Reverso**: Configuração do Nginx para servir aplicação e API
- **Deploy Automatizado**: Criação de scripts robustos para deploy em diferentes ambientes

### 4.3 Desafios de UX/UI
- **Responsividade**: Garantir experiência consistente em diferentes tamanhos de tela
- **Fluxo de Navegação**: Criação de navegação intuitiva entre as diferentes funcionalidades
- **Feedback Visual**: Implementação de indicadores de loading e estados de erro

## 5. Instruções para instalação e execução

### 5.1 Pré-requisitos
- Flutter SDK 3.7.2+
- Node.js 18+
- PostgreSQL 14+
- Docker e Docker Compose (opcional)
- Git

### 5.2 Configuração do Backend
```bash
# 1. Clone o repositório
git clone https://github.com/igormpassos/tcis-app.git
cd tcis-app

# 2. Configure o backend
cd backend
npm install

# 3. Configure as variáveis de ambiente
cp .env.example .env
# Edite o arquivo .env com suas configurações

# 4. Configure o banco de dados
npx prisma migrate dev
npx prisma generate
npm run seed

# 5. Inicie o servidor
npm start
```

### 5.3 Configuração do Flutter
```bash
# 1. Volte para o diretório raiz
cd ..

# 2. Instale as dependências do Flutter
flutter pub get

# 3. Configure os endpoints da API no arquivo de configuração
# lib/config/api_config.dart

# 4. Execute a aplicação
flutter run
```

### 5.4 Deploy com Docker
```bash
# Execute com Docker Compose
docker-compose up -d

# Ou use o script de deploy automatizado
./deploy.sh
```

### 5.5 Acesso ao Sistema
- **Aplicação Mobile**: Disponível após `flutter run`
- **API Backend**: http://localhost:3000
- **Banco de Dados**: PostgreSQL na porta 5432
- **Credenciais padrão**: admin@admin.com / 123456

## 🚀 **Execução Rápida**

### **Para Professores e Avaliadores:**

**Executar o sistema em 1 comando:**

```bash
# Linux/macOS
./iniciar-tcis.sh

# Windows
iniciar-tcis.bat
```

**Credenciais de teste:**
- **Admin:** `admin` / `123456`  
- **Operador:** `operador` / `123456`

**📋 [Ver instruções completas →](INSTRUCOES_EXECUCAO.md)**

---

## 6. Referências

FLUTTER. Flutter Documentation. Disponível em: https://docs.flutter.dev/. Acesso em: 22 ago. 2025.

NODEJS. Node.js Documentation. Disponível em: https://nodejs.org/en/docs/. Acesso em: 22 ago. 2025.

PRISMA. Prisma ORM Documentation. Disponível em: https://www.prisma.io/docs. Acesso em: 22 ago. 2025.

POSTGRESQL. PostgreSQL Documentation. Disponível em: https://www.postgresql.org/docs/. Acesso em: 22 ago. 2025.

EXPRESS. Express.js Documentation. Disponível em: https://expressjs.com/. Acesso em: 22 ago. 2025.

MATERIAL DESIGN. Material Design Guidelines. Disponível em: https://material.io/design. Acesso em: 22 ago. 2025.

DOCKER. Docker Documentation. Disponível em: https://docs.docker.com/. Acesso em: 22 ago. 2025.

JWT. JSON Web Tokens Documentation. Disponível em: https://jwt.io/. Acesso em: 22 ago. 2025.
