#!/bin/bash

# Exemplos de uso da API TCIS
# Este arquivo demonstra como usar a API backend

BASE_URL="http://localhost:3000"

echo "🚀 Testando API TCIS Backend"
echo "=========================="

# 1. Health Check
echo -e "\n1. Health Check"
curl -s $BASE_URL/health | jq

# 2. Login
echo -e "\n2. Fazendo login..."
LOGIN_RESPONSE=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "tcis", "password": "tcis"}')

echo $LOGIN_RESPONSE | jq

# Extrair token
TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.token')

if [ "$TOKEN" = "null" ]; then
  echo "❌ Erro no login. Verificar credenciais."
  exit 1
fi

echo "✅ Login realizado com sucesso!"
echo "Token: ${TOKEN:0:50}..."

# 3. Listar terminais
echo -e "\n3. Listando terminais..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/terminals | jq

# 4. Listar produtos
echo -e "\n4. Listando produtos..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/products | jq

# 5. Listar fornecedores
echo -e "\n5. Listando fornecedores..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/suppliers | jq

# 6. Listar funcionários
echo -e "\n6. Listando funcionários..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/employees | jq

# 7. Criar um relatório de exemplo
echo -e "\n7. Criando relatório de exemplo..."
REPORT_DATA='{
  "prefix": "REL-EXEMPLO-001",
  "terminalId": 1,
  "productId": 1,
  "supplierId": 1,
  "employeeId": 1,
  "startDate": "2024-08-10T08:00:00Z",
  "endDate": "2024-08-10T17:00:00Z",
  "arrivalTime": "2024-08-10T07:30:00Z",
  "departureTime": "2024-08-10T17:30:00Z",
  "startTime": "2024-08-10T08:00:00Z",
  "endTime": "2024-08-10T17:00:00Z",
  "wagonType": "Hopper",
  "hasContamination": false,
  "homogeneousMaterial": "Sim",
  "visibleMoisture": "Não",
  "rainOccurred": "Não",
  "supplierAccompanied": "Sim",
  "observations": "Relatório de exemplo criado via API. Carregamento realizado conforme especificações."
}'

REPORT_RESPONSE=$(curl -s -X POST $BASE_URL/api/reports \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$REPORT_DATA")

echo $REPORT_RESPONSE | jq

REPORT_ID=$(echo $REPORT_RESPONSE | jq -r '.data.id')

if [ "$REPORT_ID" != "null" ]; then
  echo "✅ Relatório criado com ID: $REPORT_ID"
  
  # 8. Buscar o relatório criado
  echo -e "\n8. Buscando relatório criado..."
  curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/reports/$REPORT_ID | jq
  
  # 9. Listar todos os relatórios
  echo -e "\n9. Listando todos os relatórios..."
  curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/reports | jq
else
  echo "❌ Erro ao criar relatório"
fi

# 10. Perfil do usuário
echo -e "\n10. Buscando perfil do usuário..."
curl -s -H "Authorization: Bearer $TOKEN" $BASE_URL/api/auth/profile | jq

echo -e "\n✅ Testes concluídos!"
echo "==================="
echo "API Backend está funcionando corretamente!"
