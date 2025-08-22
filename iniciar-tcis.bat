@echo off
setlocal

echo.
echo 🚀 Iniciando Sistema TCIS - Trabalho Final CSI606-2024-02
echo ===========================================================
echo.

REM Verificar se está no diretório correto
if not exist "pubspec.yaml" (
    echo ❌ Erro: Execute este script no diretório raiz do projeto
    pause
    exit /b 1
)

REM Verificar Node.js
node --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Erro: Node.js não está instalado
    echo    Baixe e instale o Node.js em: https://nodejs.org/
    pause
    exit /b 1
)

REM Verificar Flutter
flutter --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Erro: Flutter não está instalado
    echo    Baixe e instale o Flutter em: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo ✅ Dependências encontradas
echo.

REM Configurar backend
echo 🔧 Configurando backend...
cd backend

REM Instalar dependências se necessário
if not exist "node_modules" (
    echo 📦 Instalando dependências do backend...
    npm install
)

REM Verificar arquivo .env
if not exist ".env" (
    echo ⚠️  Criando arquivo .env com configurações padrão...
    echo NODE_ENV=development > .env
    echo PORT=3000 >> .env
    echo DATABASE_URL="file:./dev.db" >> .env
    echo JWT_SECRET=desenvolvimento_jwt_secret_super_seguro_123456789 >> .env
)

REM Configurar banco
echo 📊 Configurando banco de dados...
call npx prisma generate
call npx prisma db push
echo 🌱 Populando banco com dados...
call npm run seed

REM Iniciar backend
echo 🖥️  Iniciando servidor backend...
start "Backend TCIS" cmd /k "npm start"

REM Aguardar backend inicializar
echo ⏳ Aguardando backend inicializar...
timeout /t 10 /nobreak >nul

cd ..

REM Configurar Flutter
echo 📦 Configurando Flutter...
if not exist ".dart_tool" (
    echo Instalando dependências do Flutter...
    flutter pub get
)

REM Iniciar Flutter
echo 🌐 Iniciando aplicação Flutter no Chrome...
start "Flutter TCIS" cmd /k "flutter run -d chrome --web-port=8080"

echo.
echo ✅ Sistema TCIS iniciado com sucesso!
echo ==================================
echo.
echo 📊 URLs do Sistema:
echo    🌐 Aplicação Web:  http://localhost:8080
echo    🔧 API Backend:    http://localhost:3000
echo    📊 Health Check:   http://localhost:3000/health
echo.
echo 👥 Credenciais de Teste:
echo    🔑 Administrador:  admin / 123456
echo    👤 Operador:       operador / 123456
echo.
echo 📝 Para parar os serviços:
echo    Feche as janelas do terminal que abriram
echo.
pause
