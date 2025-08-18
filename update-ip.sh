#!/bin/bash

# Script para atualizar o IP em todos os arquivos de configuração
# Uso: ./update-ip.sh [novo_ip]

OLD_IP="192.168.1.224"
NEW_IP=${1:-$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)}

if [ -z "$NEW_IP" ]; then
    echo "❌ Erro: Não foi possível detectar o IP atual"
    echo "Use: $0 [ip]"
    exit 1
fi

echo "🔄 Atualizando IP de $OLD_IP para $NEW_IP..."

# Arquivos para atualizar
FILES=(
    "lib/services/api_service.dart"
    "start-tcis.sh"
    "backend/.env"
    "backend/server.js"
)

# Atualizar cada arquivo
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "📝 Atualizando $file..."
        sed -i "" "s/$OLD_IP/$NEW_IP/g" "$file"
        
        # Atualizar também a variável OLD_IP para a próxima execução
        sed -i "" "s/OLD_IP=\".*\"/OLD_IP=\"$NEW_IP\"/" "$0"
    else
        echo "⚠️  Arquivo não encontrado: $file"
    fi
done

echo "✅ IP atualizado com sucesso!"
echo "📊 Novo IP: $NEW_IP"
echo ""
echo "🔄 Para aplicar as mudanças, reinicie o backend:"
echo "   cd backend && npm run dev"
