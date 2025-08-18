#!/bin/bash

# Script para verificar IDs disponíveis no banco

BASE_URL="http://localhost:3000/api"

echo "=== VERIFICAÇÃO DE IDs NO BANCO ==="
echo

# Fazer login
TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "admin123"}' | \
  grep -o '"token":"[^"]*"' | sed 's/"token":"\(.*\)"/\1/')

if [ -z "$TOKEN" ]; then
  echo "❌ Erro no login"
  exit 1
fi

echo "✅ Token obtido!"
echo

# Verificar terminais
echo "📍 TERMINAIS:"
curl -s -X GET "$BASE_URL/terminals" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {id, name, code}' 2>/dev/null
echo

# Verificar produtos
echo "📦 PRODUTOS:"
curl -s -X GET "$BASE_URL/products" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {id, name, code}' 2>/dev/null
echo

# Verificar fornecedores
echo "🏢 FORNECEDORES:"
curl -s -X GET "$BASE_URL/suppliers" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {id, name, code}' 2>/dev/null
echo

# Verificar funcionários
echo "👥 FUNCIONÁRIOS:"
curl -s -X GET "$BASE_URL/employees" \
  -H "Authorization: Bearer $TOKEN" | jq '.data[] | {id, name, code}' 2>/dev/null
echo

echo "=== FIM DA VERIFICAÇÃO ==="
