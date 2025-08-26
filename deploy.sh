#!/bin/bash

# Script para build e deploy no Easypanel
set -e

echo "🚀 Iniciando processo de deploy para Easypanel..."

# Verificar se as variáveis de ambiente estão configuradas
if [ ! -f ".env" ]; then
    echo "❌ Arquivo .env não encontrado!"
    echo "📝 Copie o arquivo .env.example para .env e configure as variáveis:"
    echo "   cp .env.example .env"
    echo "   # Edite o arquivo .env com suas configurações"
    exit 1
fi

# Carregar variáveis do .env
source .env

# Verificar variáveis obrigatórias
if [ -z "$DB_PASSWORD" ] || [ -z "$JWT_SECRET" ] || [ -z "$DOMAIN" ]; then
    echo "❌ Variáveis obrigatórias não configuradas no .env:"
    echo "   - DB_PASSWORD"
    echo "   - JWT_SECRET"
    echo "   - DOMAIN"
    exit 1
fi

echo "✅ Variáveis de ambiente configuradas"

# Build das imagens
echo "🔨 Fazendo build das imagens Docker..."
docker-compose build --no-cache

echo "✅ Build concluído com sucesso!"
echo "📦 Imagens prontas para deploy no Easypanel"
echo ""
echo "📋 Próximos passos no Easypanel:"
echo "1. Faça upload deste projeto para seu servidor"
echo "2. Configure as variáveis de ambiente no painel"
echo "3. Execute: docker-compose up -d"
echo ""
echo "🌐 Após o deploy, sua aplicação estará disponível em:"
echo "   Frontend: https://$DOMAIN"
echo "   Backend API: https://$DOMAIN/api"
echo ""
echo "🔧 Para acessar o banco de dados:"
echo "   Host: postgres"
echo "   Port: 5432"
echo "   Database: tcis_db"
echo "   User: postgres"
echo "   Password: [DB_PASSWORD do .env]"
