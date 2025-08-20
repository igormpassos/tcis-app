#!/bin/bash

# Script para build e deploy estático no Easypanel
set -e

echo "🚀 Build local e deploy estático para Easypanel"
echo "================================================"

# 1. Build Flutter Web localmente
echo "📦 Fazendo build do Flutter Web..."
flutter build web --release

if [ $? -eq 0 ]; then
    echo "✅ Build Flutter concluído com sucesso!"
else
    echo "❌ Erro no build Flutter!"
    exit 1
fi

# 2. Verificar se o build foi criado
if [ ! -d "build/web" ]; then
    echo "❌ Diretório build/web não encontrado!"
    exit 1
fi

echo "📂 Arquivos gerados:"
ls -la build/web/

# 3. Criar tarball para upload
echo "📦 Criando arquivo para upload..."
tar -czf tcis-web-build.tar.gz build/web nginx.conf Dockerfile.static

echo ""
echo "✅ Build concluído com sucesso!"
echo ""
echo "📋 Próximos passos no Easypanel:"
echo "1. Faça upload do arquivo: tcis-web-build.tar.gz"
echo "2. Extraia no servidor: tar -xzf tcis-web-build.tar.gz"
echo "3. Renomeie o Dockerfile: mv Dockerfile.static Dockerfile"
echo "4. Build a imagem: docker build -t tcis-web ."
echo "5. Execute: docker run -d -p 80:80 tcis-web"
echo ""
echo "🌐 Ou use docker-compose com o arquivo simplificado"
