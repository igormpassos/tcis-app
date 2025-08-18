#!/bin/bash

# Script para testar a API de relatórios do TCIS

BASE_URL="http://localhost:3000/api"

echo "=== TESTE DA API DE RELATÓRIOS TCIS ==="
echo

# Passo 1: Login para obter token
echo "1. Fazendo login..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{
    "username": "tcis",
    "password": "tcis"
  }')

# Extrair o token da resposta
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | sed 's/"token":"\(.*\)"/\1/')

if [ -z "$TOKEN" ]; then
  echo "❌ Erro no login. Resposta:"
  echo $LOGIN_RESPONSE
  exit 1
fi

echo "✅ Login realizado com sucesso!"
echo "Token: ${TOKEN:0:20}..."
echo

# Passo 2: Criar relatório
echo "2. Criando relatório..."
REPORT_RESPONSE=$(curl -s -X POST "$BASE_URL/reports" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "prefix": "TESTE-001",
    "terminalId": 15,
    "productId": null,
    "supplierId": null,
    "employeeId": null,
    "startDateTime": "2025-08-15T12:00:00.000Z",
    "endDateTime": "2025-08-15T16:00:00.000Z",
    "arrivalDateTime": "2025-08-15T11:45:00.000Z",
    "departureDateTime": "2025-08-15T16:15:00.000Z",
    "status": 1,
    "wagonType": "Graneleiro",
    "hasContamination": false,
    "contaminationDescription": "",
    "homogeneousMaterial": "Sim",
    "visibleMoisture": "Não",
    "rainOccurred": "Não",
    "supplierAccompanied": "Sim",
    "observations": "Teste de relatório via curl"
  }')

echo "Resposta do servidor:"
echo $REPORT_RESPONSE | jq '.' 2>/dev/null || echo $REPORT_RESPONSE
echo

# Verificar se foi criado com sucesso
SUCCESS=$(echo $REPORT_RESPONSE | grep -o '"success":true')
if [ -n "$SUCCESS" ]; then
  echo "✅ Relatório criado com sucesso!"
  
  # Extrair ID do relatório se possível
  REPORT_ID=$(echo $REPORT_RESPONSE | grep -o '"id":"[^"]*"' | sed 's/"id":"\(.*\)"/\1/')
  if [ -n "$REPORT_ID" ]; then
    echo "ID do relatório: $REPORT_ID"
    
    # Passo 3: Buscar o relatório criado
    echo
    echo "3. Buscando relatório criado..."
    GET_RESPONSE=$(curl -s -X GET "$BASE_URL/reports/$REPORT_ID" \
      -H "Authorization: Bearer $TOKEN")
    
    echo "Dados do relatório:"
    echo $GET_RESPONSE | jq '.' 2>/dev/null || echo $GET_RESPONSE
  fi
else
  echo "❌ Erro ao criar relatório!"
fi

echo
echo "=== FIM DO TESTE ==="
