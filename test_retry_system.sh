#!/bin/bash

# Script para testar cenários de falha no sistema de envio de relatórios
# Este script simula diferentes tipos de erro para validar o retry system

echo "🧪 Testando Sistema de Envio de Relatórios com Retry"
echo "=================================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para simular erro de rede
test_network_error() {
    echo -e "\n${BLUE}📡 Testando: Erro de Rede${NC}"
    echo "Simulando desconexão da internet..."
    
    # Desabilitar WiFi temporariamente (macOS)
    networksetup -setairportpower en0 off
    echo "WiFi desabilitado - teste de retry por falta de conexão"
    
    sleep 3
    
    # Reabilitar WiFi
    networksetup -setairportpower en0 on
    echo "WiFi reabilitado"
    
    echo -e "${GREEN}✅ Teste de erro de rede concluído${NC}"
}

# Função para testar erro de servidor (simulado)
test_server_error() {
    echo -e "\n${BLUE}🖥️ Testando: Erro de Servidor${NC}"
    echo "Para testar erro de servidor:"
    echo "1. Modifique temporariamente a API_BASE_URL no constants.dart"
    echo "2. Use uma URL inválida como 'https://invalid-api.example.com'"
    echo "3. Teste o envio de relatório"
    echo "4. Verifique se o retry funciona corretamente"
    echo "5. Restaure a URL original"
    
    echo -e "${YELLOW}⚠️ Teste manual necessário para erro de servidor${NC}"
}

# Função para testar upload de arquivos grandes
test_large_file_upload() {
    echo -e "\n${BLUE}📁 Testando: Upload de Arquivos Grandes${NC}"
    
    # Criar arquivo de teste de 10MB
    dd if=/dev/zero of=/tmp/test_large_image.jpg bs=1024 count=10240 2>/dev/null
    
    echo "Arquivo de teste criado: /tmp/test_large_image.jpg (10MB)"
    echo "Para testar:"
    echo "1. Adicione este arquivo como imagem no relatório"
    echo "2. Teste o envio"
    echo "3. Verifique timeout e retry de upload"
    
    # Limpar arquivo de teste
    rm -f /tmp/test_large_image.jpg
    
    echo -e "${GREEN}✅ Arquivo de teste removido${NC}"
}

# Função para verificar logs do backend
check_backend_logs() {
    echo -e "\n${BLUE}📋 Verificando Logs do Backend${NC}"
    
    if [ -d "./backend" ]; then
        echo "Backend encontrado. Para verificar logs:"
        echo "1. cd backend"
        echo "2. npm run dev (ou pm2 logs se usando PM2)"
        echo "3. Monitore logs durante testes de falha"
    else
        echo -e "${YELLOW}⚠️ Diretório backend não encontrado${NC}"
    fi
}

# Função para testar cenários de PDF
test_pdf_scenarios() {
    echo -e "\n${BLUE}📄 Testando: Cenários de PDF${NC}"
    echo "Cenários para testar manualmente:"
    echo "1. Relatório com muitas imagens (>5)"
    echo "2. Imagens de alta resolução"
    echo "3. Campos com muito texto"
    echo "4. Caracteres especiais nos campos"
    echo "5. Falha de upload do PDF gerado"
    
    echo -e "${YELLOW}⚠️ Testes manuais necessários para PDF${NC}"
}

# Função principal
main() {
    echo "Escolha o tipo de teste:"
    echo "1. Erro de Rede"
    echo "2. Erro de Servidor (manual)"
    echo "3. Upload de Arquivos Grandes"
    echo "4. Verificar Logs Backend"
    echo "5. Cenários de PDF (manual)"
    echo "6. Executar todos os testes automáticos"
    echo "0. Sair"
    
    read -p "Digite sua escolha (0-6): " choice
    
    case $choice in
        1)
            test_network_error
            ;;
        2)
            test_server_error
            ;;
        3)
            test_large_file_upload
            ;;
        4)
            check_backend_logs
            ;;
        5)
            test_pdf_scenarios
            ;;
        6)
            echo -e "\n${BLUE}🔄 Executando todos os testes automáticos...${NC}"
            test_network_error
            test_large_file_upload
            check_backend_logs
            echo -e "\n${GREEN}✅ Testes automáticos concluídos${NC}"
            ;;
        0)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção inválida${NC}"
            main
            ;;
    esac
}

# Verificações iniciais
echo -e "${BLUE}🔍 Verificações Iniciais${NC}"

# Verificar se está no diretório correto
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}❌ Erro: Execute este script no diretório raiz do projeto Flutter${NC}"
    exit 1
fi

# Verificar se o app está buildado
if [ ! -d "build" ]; then
    echo -e "${YELLOW}⚠️ Aviso: Build não encontrado. Execute 'flutter build' antes dos testes${NC}"
fi

# Verificar backend
if [ -d "backend" ]; then
    echo -e "${GREEN}✅ Backend encontrado${NC}"
else
    echo -e "${YELLOW}⚠️ Backend não encontrado no diretório atual${NC}"
fi

echo -e "${GREEN}✅ Verificações iniciais concluídas${NC}"

# Instruções para teste manual
echo -e "\n${BLUE}📖 Instruções para Teste Manual${NC}"
echo "1. Abra o app Flutter em um dispositivo/emulador"
echo "2. Navegue para criar novo relatório"
echo "3. Preencha os dados necessários"
echo "4. Execute os testes de falha enquanto tenta enviar"
echo "5. Observe o comportamento do retry system"
echo "6. Verifique as mensagens de erro e progresso"

# Menu principal
main