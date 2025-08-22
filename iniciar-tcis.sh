#!/bin/bash

echo "🚀 Iniciando Sistema TCIS - Trabalho Final CSI606-2024-02"
echo "==========================================================="
echo ""

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Erro: Execute este script no diretório raiz do projeto"
    exit 1
fi

# Função para verificar se um comando existe
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ Erro: $1 não está instalado"
        echo "   Instale $1 e tente novamente"
        exit 1
    fi
}

# Verificar dependências
echo "🔍 Verificando dependências..."
check_command "node"
check_command "npm"
check_command "flutter"

echo "✅ Todas as dependências encontradas"
echo ""

# Função para aguardar o backend estar pronto
wait_for_backend() {
    echo "⏳ Aguardando backend inicializar..."
    for i in {1..30}; do
        if curl -s http://localhost:3000/health > /dev/null 2>&1; then
            echo "✅ Backend está funcionando!"
            return 0
        fi
        echo "   Tentativa $i/30..."
        sleep 2
    done
    echo "❌ Timeout: Backend não respondeu em 60 segundos"
    return 1
}

# Configurar backend
echo "🔧 Configurando backend..."
cd backend

# Verificar se node_modules existe
if [ ! -d "node_modules" ]; then
    echo "📦 Instalando dependências do backend..."
    npm install
fi

# Verificar se o banco de dados foi configurado
echo "🗄️  Configurando banco de dados..."
if [ ! -f ".env" ]; then
    echo "⚠️  Arquivo .env não encontrado, criando com configurações padrão..."
    cat > .env << EOF
NODE_ENV=development
PORT=3000
DATABASE_URL="postgresql://tcis:tcis123@localhost:5432/tcis_dev?schema=public"
JWT_SECRET=desenvolvimento_jwt_secret_super_seguro_123456789
EOF
fi

# Executar migrações e seed
echo "📊 Executando migrações do banco..."
npx prisma generate
npx prisma migrate deploy 2>/dev/null || npx prisma db push
echo "🌱 Populando banco com dados iniciais..."
npm run seed

# Iniciar backend em segundo plano
echo "🖥️  Iniciando servidor backend..."
npm start &
BACKEND_PID=$!

# Voltar para o diretório raiz
cd ..

# Aguardar backend estar pronto
if ! wait_for_backend; then
    echo "❌ Falha ao iniciar backend, encerrando..."
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi

echo ""
echo "🌐 Iniciando aplicação Flutter no Chrome..."
echo ""

# Verificar se as dependências do Flutter estão instaladas
if [ ! -d ".dart_tool" ]; then
    echo "📦 Instalando dependências do Flutter..."
    flutter pub get
fi

# Iniciar Flutter no Chrome
echo "🚀 Abrindo aplicação no navegador..."
flutter run -d chrome --web-port=8080 &
FLUTTER_PID=$!

# Mostrar informações importantes
echo ""
echo "✅ Sistema TCIS iniciado com sucesso!"
echo "=================================="
echo ""
echo "📊 URLs do Sistema:"
echo "   🌐 Aplicação Web:  http://localhost:8080"
echo "   🔧 API Backend:    http://localhost:3000"
echo "   📊 Health Check:   http://localhost:3000/health"
echo ""
echo "👥 Credenciais de Teste:"
echo "   🔑 Administrador:  admin / 123456"
echo "   👤 Operador:       operador / 123456"
echo ""
echo "📝 Para parar os serviços:"
echo "   Pressione Ctrl+C neste terminal"
echo ""

# Função para limpeza ao sair
cleanup() {
    echo ""
    echo "🛑 Encerrando serviços..."
    kill $BACKEND_PID 2>/dev/null
    kill $FLUTTER_PID 2>/dev/null
    echo "✅ Serviços encerrados"
    exit 0
}

# Capturar sinais de interrupção
trap cleanup SIGINT SIGTERM

# Aguardar até que o usuário pressione Ctrl+C
echo "⏳ Aguardando... (Pressione Ctrl+C para parar)"
wait