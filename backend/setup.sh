#!/bin/bash

# Script de configuração inicial do backend TCIS
# Execute: chmod +x setup.sh && ./setup.sh

echo "🚀 Configuração inicial do Backend TCIS"
echo "======================================"

# Verificar se Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js não encontrado. Instale Node.js 18+ primeiro."
    exit 1
fi

echo "✅ Node.js encontrado: $(node --version)"

# Verificar se PostgreSQL está instalado
if ! command -v psql &> /dev/null; then
    echo "❌ PostgreSQL não encontrado."
    echo "   Para instalar no macOS: brew install postgresql"
    echo "   Para iniciar: brew services start postgresql"
    exit 1
fi

echo "✅ PostgreSQL encontrado"

# Instalar dependências
echo "📦 Instalando dependências..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Erro ao instalar dependências"
    exit 1
fi

echo "✅ Dependências instaladas"

# Configurar arquivo .env
if [ ! -f .env ]; then
    echo "🔧 Configurando arquivo .env..."
    cp .env.example .env
    echo "✅ Arquivo .env criado. Edite-o se necessário."
else
    echo "ℹ️  Arquivo .env já existe"
fi

# Verificar se banco existe, se não, criar
echo "🗄️  Verificando banco de dados..."
psql -lqt | cut -d \| -f 1 | grep -qw tcis_db

if [ $? -ne 0 ]; then
    echo "📊 Criando banco de dados tcis_db..."
    createdb tcis_db
    
    if [ $? -ne 0 ]; then
        echo "❌ Erro ao criar banco de dados"
        echo "   Verifique se o PostgreSQL está rodando"
        echo "   Comando: brew services start postgresql"
        exit 1
    fi
    
    echo "✅ Banco de dados criado"
else
    echo "✅ Banco de dados já existe"
fi

# Gerar cliente Prisma
echo "🔄 Gerando cliente Prisma..."
npx prisma generate

if [ $? -ne 0 ]; then
    echo "❌ Erro ao gerar cliente Prisma"
    exit 1
fi

# Executar migrações
echo "🔄 Executando migrações..."
npx prisma migrate deploy

if [ $? -ne 0 ]; then
    echo "🆕 Criando primeira migração..."
    npx prisma migrate dev --name init
    
    if [ $? -ne 0 ]; then
        echo "❌ Erro ao executar migrações"
        exit 1
    fi
fi

echo "✅ Migrações executadas"

# Popular banco com dados iniciais
echo "🌱 Populando banco com dados iniciais..."
node prisma/seed.js

if [ $? -ne 0 ]; then
    echo "❌ Erro ao popular banco de dados"
    exit 1
fi

echo "✅ Dados iniciais inseridos"

# Criar diretório de uploads
echo "📁 Criando diretório de uploads..."
mkdir -p uploads/images
echo "✅ Diretório de uploads criado"

echo ""
echo "🎉 Configuração concluída com sucesso!"
echo ""
echo "Para iniciar o servidor:"
echo "  npm run dev    # Desenvolvimento"
echo "  npm start      # Produção"
echo ""
echo "Usuário padrão:"
echo "  Username: tcis"
echo "  Password: tcis"
echo ""
echo "Health check: http://localhost:3000/health"
echo "Prisma Studio: npm run studio"
echo ""
