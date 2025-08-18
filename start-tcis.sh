#!/bin/bash

# Script para iniciar backend e frontend TCIS
echo "🚀 Iniciando TCIS App..."

# Navegar para diretório do projeto
cd "$(dirname "$0")"

# Função para cleanup ao sair
cleanup() {
    echo "🛑 Parando serviços..."
    kill $BACKEND_PID 2>/dev/null
    kill $FRONTEND_PID 2>/dev/null
    exit
}

# Configurar trap para cleanup
trap cleanup SIGINT SIGTERM

# Iniciar backend
echo "📡 Iniciando backend..."
cd backend
node server.js &
BACKEND_PID=$!
cd ..

# Esperar backend inicializar
sleep 3

# Verificar se backend está rodando
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Backend rodando na porta 3000"
else
    echo "❌ Erro: Backend não iniciou corretamente"
    exit 1
fi

# Iniciar Flutter
echo "📱 Iniciando Flutter..."
flutter run -d macos &
FRONTEND_PID=$!

# Manter script rodando
echo "🎉 TCIS App iniciado com sucesso!"
echo "Backend: http://localhost:3000"
echo "Backend (rede local): http://192.168.1.224:3000"
echo "Frontend: rodando no macOS"
echo ""
echo "📱 Para simulador iOS, use: http://192.168.1.224:3000"
echo "Pressione Ctrl+C para parar todos os serviços"

wait $FRONTEND_PID
