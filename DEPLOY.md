# 🚀 Deploy TCIS App no Easypanel

Este guia te ajudará a fazer o deploy da aplicação TCIS no seu VPS usando Easypanel.

## 📋 Pré-requisitos

- VPS com Easypanel instalado
- Docker e Docker Compose configurados
- Domínio apontando para seu VPS
- Certificado SSL configurado (recomendado)

## 🔧 Configuração

### 1. Preparar ambiente local

```bash
# 1. Copiar arquivo de configuração
cp .env.example .env

# 2. Editar com suas configurações
nano .env
```

Configure as seguintes variáveis no `.env`:
```bash
# Senha do banco PostgreSQL (use uma senha forte!)
DB_PASSWORD=sua_senha_super_segura_aqui

# Secret para JWT (gere uma chave aleatória forte!)
JWT_SECRET=seu_jwt_secret_super_seguro_aqui

# Seu domínio
DOMAIN=seu-dominio.com
```

### 2. Build local (opcional)

```bash
# Testar build local
./deploy.sh
```

## 🌐 Deploy no Easypanel

### Método 1: Upload direto

1. **Compactar projeto:**
   ```bash
   tar -czf tcis-app.tar.gz --exclude=node_modules --exclude=build --exclude=.git .
   ```

2. **Fazer upload para o servidor via Easypanel File Manager**

3. **Extrair no servidor:**
   ```bash
   cd /path/to/your/app
   tar -xzf tcis-app.tar.gz
   ```

### Método 2: Git Clone

1. **No servidor, clonar o repositório:**
   ```bash
   git clone https://github.com/seu-usuario/tcis-app.git
   cd tcis-app
   ```

2. **Configurar environment:**
   ```bash
   cp .env.example .env
   nano .env  # Editar com suas configurações
   ```

### 3. Executar no servidor

```bash
# 1. Build e subir containers
docker-compose up -d --build

# 2. Verificar status
docker-compose ps

# 3. Ver logs se necessário
docker-compose logs -f
```

## 🗄️ Configuração do Banco de Dados

O banco PostgreSQL será criado automaticamente. Para executar seeds iniciais:

```bash
# Entrar no container do backend
docker-compose exec backend sh

# Executar seeds
npm run seed
```

## 🔒 Configurações de Segurança

### 1. Firewall
Certifique-se de que apenas as portas necessárias estão abertas:
- 80 (HTTP)
- 443 (HTTPS)
- 22 (SSH)

### 2. SSL/HTTPS
Configure SSL através do Easypanel ou use Nginx Proxy Manager.

### 3. Backup
Configure backups regulares do banco PostgreSQL:
```bash
# Script de backup
docker-compose exec postgres pg_dump -U postgres tcis_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

## 📊 Monitoramento

### Ver logs em tempo real:
```bash
# Todos os serviços
docker-compose logs -f

# Apenas backend
docker-compose logs -f backend

# Apenas frontend
docker-compose logs -f frontend

# Apenas banco
docker-compose logs -f postgres
```

### Verificar status:
```bash
docker-compose ps
```

## 🔧 Manutenção

### Atualizar aplicação:
```bash
# 1. Fazer pull das mudanças
git pull origin main

# 2. Rebuild e restart
docker-compose up -d --build

# 3. Executar migrações se necessário
docker-compose exec backend npx prisma migrate deploy
```

### Restart serviços:
```bash
# Restart tudo
docker-compose restart

# Restart específico
docker-compose restart backend
```

### Backup do banco:
```bash
# Criar backup
docker-compose exec postgres pg_dump -U postgres -d tcis_db > tcis_backup_$(date +%Y%m%d).sql

# Restaurar backup
docker-compose exec -T postgres psql -U postgres -d tcis_db < tcis_backup.sql
```

## 🌍 URLs da Aplicação

Após o deploy bem-sucedido:

- **Frontend (Flutter Web):** `https://seu-dominio.com`
- **Backend API:** `https://seu-dominio.com/api`
- **Documentação API:** `https://seu-dominio.com/api/docs` (se implementada)

## 🐛 Troubleshooting

### Problemas comuns:

1. **Erro de conexão com banco:**
   - Verificar se o PostgreSQL está rodando: `docker-compose logs postgres`
   - Verificar variáveis de ambiente no `.env`

2. **Frontend não carrega:**
   - Verificar se o build do Flutter foi bem-sucedido
   - Verificar logs do nginx: `docker-compose logs frontend`

3. **API não responde:**
   - Verificar logs do backend: `docker-compose logs backend`
   - Verificar se as migrações do Prisma foram executadas

4. **Problemas de CORS:**
   - Verificar configuração `ALLOWED_ORIGINS` no backend
   - Verificar configuração nginx

### Comandos úteis para debug:

```bash
# Entrar no container do backend
docker-compose exec backend sh

# Entrar no container do banco
docker-compose exec postgres psql -U postgres -d tcis_db

# Ver todas as variáveis de ambiente
docker-compose config
```

## 📞 Suporte

Se encontrar problemas durante o deploy, verifique:

1. ✅ Todas as variáveis de ambiente estão configuradas
2. ✅ Docker e Docker Compose estão funcionando
3. ✅ Domínio está apontando para o servidor
4. ✅ Portas necessárias estão abertas no firewall

---

**Desenvolvido com ❤️ para facilitar o deploy da aplicação TCIS**
