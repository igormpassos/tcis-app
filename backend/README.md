# Backend TCIS - API de Gerenciamento de Relatórios

## Descrição

API RESTful para gerenciamento de relatórios de inspeção de carga desenvolvida em Node.js com Express, Prisma e PostgreSQL.

## Requisitos

- Node.js 18+ 
- PostgreSQL 12+
- npm ou yarn

## Instalação

1. **Clone o repositório e navegue até a pasta do backend**
```bash
cd backend
```

2. **Instale as dependências**
```bash
npm install
```

3. **Configure o banco de dados PostgreSQL**
```bash
# Instalar PostgreSQL (macOS com Homebrew)
brew install postgresql
brew services start postgresql

# Criar banco de dados
createdb tcis_db
```

4. **Configure as variáveis de ambiente**
```bash
cp .env.example .env
# Edite o arquivo .env com suas configurações
```

5. **Execute as migrações do banco**
```bash
npm run migrate
```

6. **Popule o banco com dados iniciais**
```bash
npm run seed
```

7. **Inicie o servidor**
```bash
# Desenvolvimento
npm run dev

# Produção
npm start
```

## Estrutura da API

### Autenticação
- `POST /api/auth/login` - Login do usuário
- `POST /api/auth/register` - Registro (apenas admin)
- `GET /api/auth/profile` - Perfil do usuário
- `PUT /api/auth/profile` - Atualizar perfil
- `POST /api/auth/change-password` - Alterar senha
- `POST /api/auth/verify-token` - Verificar token

### Relatórios
- `GET /api/reports` - Listar relatórios
- `POST /api/reports` - Criar relatório
- `GET /api/reports/:id` - Buscar relatório específico
- `PUT /api/reports/:id` - Atualizar relatório
- `DELETE /api/reports/:id` - Excluir relatório

### Terminais
- `GET /api/terminals` - Listar terminais
- `POST /api/terminals` - Criar terminal (admin)
- `GET /api/terminals/:id` - Buscar terminal específico
- `PUT /api/terminals/:id` - Atualizar terminal (admin)
- `DELETE /api/terminals/:id` - Excluir terminal (admin)

### Produtos
- `GET /api/products` - Listar produtos
- `GET /api/products/categories` - Listar categorias
- `POST /api/products` - Criar produto (admin)
- `GET /api/products/:id` - Buscar produto específico
- `PUT /api/products/:id` - Atualizar produto (admin)
- `DELETE /api/products/:id` - Excluir produto (admin)

### Fornecedores
- `GET /api/suppliers` - Listar fornecedores
- `POST /api/suppliers` - Criar fornecedor (admin)
- `GET /api/suppliers/:id` - Buscar fornecedor específico
- `PUT /api/suppliers/:id` - Atualizar fornecedor (admin)
- `DELETE /api/suppliers/:id` - Excluir fornecedor (admin)

### Funcionários
- `GET /api/employees` - Listar funcionários
- `GET /api/employees/positions` - Listar cargos
- `POST /api/employees` - Criar funcionário (admin)
- `GET /api/employees/:id` - Buscar funcionário específico
- `PUT /api/employees/:id` - Atualizar funcionário (admin)
- `DELETE /api/employees/:id` - Excluir funcionário (admin)

### Upload de Arquivos
- `POST /api/uploads/images/:reportId` - Upload de imagens
- `GET /api/uploads/images/:reportId` - Listar imagens do relatório
- `DELETE /api/uploads/images/:imageId` - Excluir imagem
- `GET /api/uploads/images/file/:filename` - Baixar imagem

### Utilitários
- `GET /health` - Health check da API

## Autenticação

A API utiliza JWT (JSON Web Tokens) para autenticação. 

### Login
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tcis",
    "password": "tcis"
  }'
```

### Usando o token
```bash
curl -H "Authorization: Bearer SEU_TOKEN_AQUI" \
  http://localhost:3000/api/reports
```

## Dados Padrão

Após executar o seed, você terá:

### Usuário Admin
- **Username:** tcis
- **Password:** tcis
- **Role:** ADMIN

### Terminais
- Terminal Santos (TS001)
- Terminal Rio de Janeiro (TRJ001)
- Terminal Vitória (TV001)
- Terminal Paranaguá (TP001)

### Produtos
- Minério de Ferro (MF001)
- Soja (SJ001)
- Milho (ML001)
- Açúcar (AC001)
- Celulose (CL001)

### Fornecedores
- Vale S.A. (VALE001)
- Cargill (CAR001)
- ADM do Brasil (ADM001)

### Funcionários
- Carlos Mendes (EMP001) - Inspetor de Carga
- Ana Costa (EMP002) - Supervisora de Terminal
- Roberto Lima (EMP003) - Inspetor de Carga

## Exemplos de Uso

### Criar um relatório
```bash
curl -X POST http://localhost:3000/api/reports \
  -H "Authorization: Bearer SEU_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "prefix": "REL-001",
    "terminalId": 1,
    "productId": 1,
    "startDate": "2024-08-10T08:00:00Z",
    "endDate": "2024-08-10T17:00:00Z",
    "observations": "Relatório de exemplo"
  }'
```

### Upload de imagem para um relatório
```bash
curl -X POST http://localhost:3000/api/uploads/images/REPORT_UUID \
  -H "Authorization: Bearer SEU_TOKEN" \
  -F "images=@imagem1.jpg" \
  -F "images=@imagem2.jpg"
```

## Status dos Relatórios

- **0:** Rascunho
- **1:** Finalizado  
- **2:** Enviado

## Roles de Usuário

- **ADMIN:** Acesso total, pode gerenciar usuários, terminais, produtos, etc.
- **USER:** Pode criar e gerenciar seus próprios relatórios

## Desenvolvimento

### Scripts disponíveis
```bash
npm run dev          # Iniciar em modo desenvolvimento
npm start            # Iniciar em produção
npm run migrate      # Executar migrações do banco
npm run generate     # Gerar cliente Prisma
npm run studio       # Abrir Prisma Studio
npm run seed         # Popular banco com dados iniciais
```

### Prisma Studio
Para visualizar e gerenciar os dados do banco:
```bash
npm run studio
```

## Configuração de Produção

1. Configure as variáveis de ambiente para produção
2. Configure um servidor de banco PostgreSQL
3. Execute as migrações: `npm run migrate`
4. Execute o seed: `npm run seed`
5. Use um process manager como PM2: `pm2 start server.js`

## Logs e Monitoramento

- Os logs são gerados automaticamente pelo Morgan
- Health check disponível em `/health`
- Rate limiting configurado (1000 requests por IP a cada 15 minutos)

## Segurança

- Helmet para headers de segurança
- Rate limiting
- Validação de entrada com express-validator
- Autenticação JWT
- Autorização baseada em roles
- Upload seguro de arquivos com validação
- Otimização automática de imagens
