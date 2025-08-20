# 🚨 SOLUÇÃO DEFINITIVA PARA EASYPANEL

## ⚠️ IMPORTANTE: Build Local Obrigatório

O Dockerfile agora é **ESTÁTICO** - você DEVE fazer o build local antes do deploy.

## ✅ PASSOS OBRIGATÓRIOS

### 1. Build Local (OBRIGATÓRIO)
```bash
# Execute SEMPRE antes do deploy
./build-static.sh
```

### 2. Commit e Push
```bash
git add .
git commit -m "build: Adicionar arquivos web compilados"
git push
```

### 3. Deploy no Easypanel
Agora o Dockerfile simplesmente copia os arquivos já compilados.

## 🔧 Dockerfile Atual
```dockerfile
# DOCKERFILE ESTÁTICO - USE APENAS APÓS flutter build web
FROM nginx:alpine
COPY build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## 🚀 Alternativa: Deploy Manual

Se preferir, pode fazer deploy manual:

```bash
# No servidor Easypanel
docker run -d -p 80:80 -v $(pwd)/build/web:/usr/share/nginx/html nginx:alpine
```
docker build -f Dockerfile.static -t tcis-web .
docker run -d -p 80:80 tcis-web
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
