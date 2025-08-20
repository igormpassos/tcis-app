# 🎯 Quick Deploy - TCIS App

## 🚀 Deploy Rápido (2 minutos)

### 1. Configuração automática
```bash
./setup.sh
```

### 2. Build e teste local (opcional)
```bash
./deploy.sh
```

### 3. Upload para servidor
```bash
# Compactar projeto
tar -czf tcis-app.tar.gz --exclude=node_modules --exclude=build .

# Upload via Easypanel ou scp
scp tcis-app.tar.gz user@seu-servidor:/path/to/app/
```

### 4. Deploy no servidor
```bash
# Extrair
tar -xzf tcis-app.tar.gz

# Deploy
docker-compose up -d --build
```

## 📋 Checklist de Deploy

### Antes do deploy:
- [ ] Domínio configurado e apontando para o VPS
- [ ] SSL/HTTPS configurado (recomendado)
- [ ] Arquivo `.env` criado com configurações
- [ ] Docker e Docker Compose instalados no servidor

### Após o deploy:
- [ ] Containers rodando: `docker-compose ps`
- [ ] Frontend acessível: `https://seu-dominio.com`
- [ ] API respondendo: `https://seu-dominio.com/api/health`
- [ ] Banco de dados funcionando

## 🔧 Comandos Úteis

```bash
# Ver status
docker-compose ps

# Ver logs
docker-compose logs -f

# Restart
docker-compose restart

# Backup do banco
docker-compose exec postgres pg_dump -U postgres tcis_db > backup.sql

# Executar seeds
docker-compose exec backend npm run seed
```

## 🆘 Problemas Comuns

| Problema | Solução |
|----------|---------|
| Container não inicia | `docker-compose logs [service]` |
| API não responde | Verificar variáveis `.env` |
| Frontend não carrega | Verificar build Flutter |
| CORS errors | Verificar `ALLOWED_ORIGINS` |

## 📞 Suporte

Para problemas específicos, verificar:
1. 📖 [DEPLOY.md](./DEPLOY.md) - Documentação completa
2. 🔍 Logs dos containers
3. 🌐 Configurações de DNS/SSL

---
**Deploy simplificado para TCIS App** 🚀
