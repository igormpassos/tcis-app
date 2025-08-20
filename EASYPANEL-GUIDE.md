# 🎛️ Guia Específico para Easypanel

## 📋 Pré-requisitos no Easypanel

1. **VPS com Easypanel instalado**
2. **Docker e Docker Compose configurados**
3. **Domínio apontando para seu servidor**

## 🚀 Deploy Passo a Passo no Easypanel

### Método 1: Upload de Arquivos (Recomendado)

#### 1. Preparar projeto localmente
```bash
# 1. Configurar variáveis
./setup.sh

# 2. Testar build (opcional)
./deploy.sh

# 3. Compactar projeto
tar -czf tcis-app.tar.gz --exclude=node_modules --exclude=build --exclude=.git .
```

#### 2. Upload via Easypanel
1. Acesse o **File Manager** no Easypanel
2. Navegue até `/home/user/apps/` (ou diretório de sua escolha)
3. Crie pasta: `mkdir tcis-app`
4. Faça upload do arquivo `tcis-app.tar.gz`
5. Extraia: `tar -xzf tcis-app.tar.gz`

#### 3. Deploy via Terminal Easypanel
```bash
cd /home/user/apps/tcis-app
docker-compose up -d --build
```

### Método 2: Git Clone

#### 1. No terminal do Easypanel
```bash
cd /home/user/apps/
git clone https://github.com/seu-usuario/tcis-app.git
cd tcis-app
```

#### 2. Configurar ambiente
```bash
./setup.sh
```

#### 3. Deploy
```bash
docker-compose up -d --build
```

## ⚙️ Configuração de Serviços no Easypanel

### 1. Criar Aplicação

**No painel Easypanel:**

1. **Criar Nova Aplicação**
   - Nome: `tcis-app`
   - Tipo: `Docker Compose`

2. **Configurar Source**
   - Tipo: `Git Repository` ou `Upload`
   - URL: seu repositório (se usando Git)

3. **Configurar Environment Variables**
   ```
   DB_PASSWORD=sua_senha_segura
   JWT_SECRET=seu_jwt_secret
   DOMAIN=seu-dominio.com
   ```

4. **Configurar Domínios**
   - Domínio principal: `seu-dominio.com`
   - Subdomínio API: `api.seu-dominio.com` (opcional)

### 2. Configurar SSL

**No Easypanel:**
1. Vá para **SSL/TLS**
2. Selecione **Let's Encrypt**
3. Adicione seu domínio
4. Aguarde a geração do certificado

### 3. Configurar Proxy (se necessário)

Se você quiser usar subdomínios separados:

**Frontend:** `app.seu-dominio.com` → `localhost:80`
**Backend:** `api.seu-dominio.com` → `localhost:3000`

## 📊 Monitoramento no Easypanel

### 1. Ver Logs
```bash
# No terminal Easypanel
cd /path/to/tcis-app
docker-compose logs -f
```

### 2. Status dos Containers
```bash
docker-compose ps
```

### 3. Usar script de manutenção
```bash
./maintenance.sh status
./maintenance.sh logs
./maintenance.sh monitor
```

## 🔧 Configurações Específicas do Easypanel

### 1. Arquivo docker-compose.yml para Easypanel

Se preferir, pode usar esta versão simplificada:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: tcis_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    
  backend:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://postgres:${DB_PASSWORD}@postgres:5432/tcis_db
      JWT_SECRET: ${JWT_SECRET}
      JWT_EXPIRES_IN: 24h
      PORT: 3000
      NODE_ENV: production
      ALLOWED_ORIGINS: https://${DOMAIN}
    volumes:
      - backend_uploads:/app/uploads
    ports:
      - "3000:3000"
    depends_on:
      - postgres
    restart: unless-stopped
    
  frontend:
    build: .
    dockerfile: Dockerfile.web
    ports:
      - "80:80"
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  postgres_data:
  backend_uploads:
```

### 2. Configurar Reverse Proxy

No Easypanel, configure o reverse proxy para:
- Redirecionar `seu-dominio.com` → container frontend (porta 80)
- Redirecionar `seu-dominio.com/api` → container backend (porta 3000)

### 3. Configurar Backups Automáticos

No cron do Easypanel:
```bash
# Backup diário às 2h da manhã
0 2 * * * cd /path/to/tcis-app && ./maintenance.sh backup
```

## 🆘 Troubleshooting Easypanel

### Problemas Comuns:

| Problema | Solução |
|----------|---------|
| Build falha | Verificar logs: `docker-compose logs` |
| Domínio não resolve | Verificar DNS e SSL no painel |
| API não responde | Verificar proxy e portas |
| Banco não conecta | Verificar variáveis de ambiente |

### Comandos de Debug:

```bash
# Ver recursos do sistema
docker system df

# Ver logs específicos
docker-compose logs postgres
docker-compose logs backend
docker-compose logs frontend

# Testar conectividade
curl -I http://localhost:80
curl -I http://localhost:3000/health

# Ver processos
docker-compose top
```

## 📈 Otimizações para Produção

### 1. Limites de Recursos
Adicione ao docker-compose.yml:
```yaml
deploy:
  resources:
    limits:
      memory: 512M
      cpus: '0.5'
```

### 2. Health Checks
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### 3. Logs Rotativos
Configure no Easypanel:
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

## 🎯 Checklist Final

- [ ] ✅ Projeto enviado para servidor
- [ ] ✅ Variáveis de ambiente configuradas
- [ ] ✅ SSL configurado
- [ ] ✅ Domínio funcionando
- [ ] ✅ API respondendo em `/api/health`
- [ ] ✅ Frontend carregando
- [ ] ✅ Banco de dados funcional
- [ ] ✅ Backups configurados
- [ ] ✅ Monitoramento ativo

---

**🚀 Sua aplicação TCIS está pronta para produção no Easypanel!**
