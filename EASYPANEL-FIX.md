# 🚨 SOLUÇÃO RÁPIDA PARA EASYPANEL

## Problema Identificado
O Easypanel está procurando um `Dockerfile` na raiz, mas só existia `Dockerfile.web`.

## ✅ Solução Aplicada

Criei o `Dockerfile` principal na raiz do projeto que builda o frontend Flutter Web.

## 🔧 Configuração no Easypanel

### Opção 1: Deploy Apenas Frontend (Mais Simples)

1. **No Easypanel, configure:**
   - **Build Context:** `/` (raiz)
   - **Dockerfile:** `Dockerfile`
   - **Port:** `80`

2. **Para o backend, crie um serviço separado:**
   - **Build Context:** `/backend`
   - **Dockerfile:** `backend/Dockerfile`
   - **Port:** `3000`

3. **Para PostgreSQL, use o serviço gerenciado do Easypanel**

### Opção 2: Docker Compose (Recomendado)

Use o arquivo `docker-compose.prod.yml` que criei:

```bash
# No servidor
docker-compose -f docker-compose.prod.yml up -d
```

### Opção 3: Deploy Manual Rápido

1. **Frontend (Porta 80):**
   ```bash
   docker build -t tcis-frontend .
   docker run -d -p 80:80 tcis-frontend
   ```

2. **Backend (Porta 3000):**
   ```bash
   cd backend
   docker build -t tcis-backend .
   docker run -d -p 3000:3000 -e DATABASE_URL="your_db_url" tcis-backend
   ```

## 🎯 Variáveis de Ambiente Necessárias

No Easypanel, configure:
```
DB_PASSWORD=sua_senha_segura
JWT_SECRET=seu_jwt_secret_aqui
DOMAIN=seu-dominio.com
```

## 🔄 Teste Rápido

Após o deploy, teste:
- Frontend: `http://seu-ip:80`
- Backend: `http://seu-ip:3000/health`

## 📞 Se Ainda Der Erro

1. **Verifique se o Dockerfile existe na raiz**
2. **Use build context correto no Easypanel**
3. **Ou use Docker Compose manual**

---
**Problema resolvido! 🎉**
