#!/bin/bash

# Script de configuração rápida para deploy
set -e

echo "🔧 TCIS App - Configuração rápida para deploy"
echo "============================================"
echo ""

# Função para gerar senha aleatória
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Função para gerar JWT secret
generate_jwt_secret() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-50
}

# Verificar se .env já existe
if [ -f ".env" ]; then
    echo "⚠️  Arquivo .env já existe!"
    read -p "Deseja sobrescrever? (y/N): " overwrite
    if [[ ! $overwrite =~ ^[Yy]$ ]]; then
        echo "❌ Configuração cancelada."
        exit 0
    fi
fi

# Coletar informações
echo "📝 Configure as informações de deploy:"
echo ""

# Domínio
while true; do
    read -p "🌐 Seu domínio (ex: meuapp.com): " domain
    if [[ -n "$domain" ]]; then
        break
    fi
    echo "❌ Domínio é obrigatório!"
done

# Senha do banco
read -p "🔒 Senha do PostgreSQL (deixe em branco para gerar automaticamente): " db_password
if [[ -z "$db_password" ]]; then
    db_password=$(generate_password)
    echo "🎲 Senha gerada automaticamente: $db_password"
fi

# JWT Secret
read -p "🔑 JWT Secret (deixe em branco para gerar automaticamente): " jwt_secret
if [[ -z "$jwt_secret" ]]; then
    jwt_secret=$(generate_jwt_secret)
    echo "🎲 JWT Secret gerado automaticamente"
fi

# Criar arquivo .env
cat > .env << EOF
# Configuração de produção gerada automaticamente
# Data: $(date)

# Senha do banco PostgreSQL
DB_PASSWORD=$db_password

# Secret para JWT
JWT_SECRET=$jwt_secret

# Domínio da aplicação
DOMAIN=$domain
EOF

echo ""
echo "✅ Arquivo .env criado com sucesso!"
echo ""
echo "📋 Resumo da configuração:"
echo "   Domínio: $domain"
echo "   Senha DB: $db_password"
echo "   JWT configurado: ✅"
echo ""
echo "🚀 Próximos passos:"
echo "1. Execute: ./deploy.sh (para testar localmente)"
echo "2. Faça upload do projeto para seu VPS"
echo "3. No servidor, execute: docker-compose up -d"
echo ""
echo "⚠️  IMPORTANTE: Guarde essas informações em local seguro!"
echo "   A senha do banco será necessária para acessar os dados."
echo ""
echo "🔗 URLs após o deploy:"
echo "   App: https://$domain"
echo "   API: https://$domain/api"

# Perguntar se quer fazer backup das credenciais
read -p "💾 Salvar credenciais em arquivo backup? (y/N): " backup
if [[ $backup =~ ^[Yy]$ ]]; then
    backup_file="credentials_$(date +%Y%m%d_%H%M%S).txt"
    cat > "$backup_file" << EOF
TCIS App - Credenciais de Deploy
================================
Data: $(date)
Domínio: $domain
Senha PostgreSQL: $db_password
JWT Secret: $jwt_secret

IMPORTANTE: Mantenha este arquivo em local seguro e delete após anotar as informações!
EOF
    echo "💾 Credenciais salvas em: $backup_file"
    echo "⚠️  Lembre-se de deletar este arquivo após anotar as informações!"
fi
