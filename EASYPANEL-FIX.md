# 🚨 SOLUÇÃO PARA ERRO DO FLUTTER BUILD

## Problema Atual
O Docker não consegue baixar o Flutter SDK devido a problemas de rede no servidor.

## ✅ SOLUÇÃO RÁPIDA: Build Local + Deploy Estático

### Método 1: Build Local (RECOMENDADO)

1. **Execute o script de build local:**
   ```bash
   ./build-static.sh
   ```

2. **No Easypanel:**
   - Use `Dockerfile.static` em vez do `Dockerfile` principal
   - Ou faça upload do arquivo `tcis-web-build.tar.gz`

3. **Deploy:**
   ```bash
   # Renomear Dockerfile
   mv Dockerfile.static Dockerfile
   
   # Ou usar docker-compose estático
   docker-compose -f docker-compose.static.yml up -d
   ```

### Método 2: Deploy Apenas Backend

Se o Flutter não funcionar, deploy apenas o backend:

1. **Crie serviço para backend:**
   - Build Context: `/backend`
   - Dockerfile: `backend/Dockerfile`
   - Port: `3000`

2. **Frontend: Use serviço estático**
   - Upload manual dos arquivos `build/web/`
   - Use nginx simples

## 🔧 Dockerfiles Disponíveis

- `Dockerfile` - Build completo com Flutter (problemático)
- `Dockerfile.simple` - Versão com imagem oficial
- `Dockerfile.static` - Apenas nginx com arquivos pré-construídos ✅

## 🚀 Comandos Rápidos

```bash
# Build local e preparar
./build-static.sh

# Upload para servidor
scp tcis-web-build.tar.gz user@servidor:/path/

# No servidor
tar -xzf tcis-web-build.tar.gz
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
