#!/bin/bash

echo "🧪 Testando conectividade do Flutter com Backend..."
echo ""

# Obter IP atual
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
echo "📍 IP atual detectado: $CURRENT_IP"

# Testar endpoints
echo "🔍 Testando endpoints:"
echo ""

# Health check local
echo "1️⃣ Health check (localhost):"
curl -s -w "\n⏱️  Tempo: %{time_total}s\n" http://localhost:3000/health | jq . 2>/dev/null || echo "❌ Falhou"
echo ""

# Health check rede
echo "2️⃣ Health check (rede - $CURRENT_IP):"
curl -s -w "\n⏱️  Tempo: %{time_total}s\n" http://$CURRENT_IP:3000/health | jq . 2>/dev/null || echo "❌ Falhou"
echo ""

# Testar API endpoint
echo "3️⃣ API endpoint (rede - $CURRENT_IP):"
curl -s -w "\n⏱️  Tempo: %{time_total}s\n" http://$CURRENT_IP:3000/api/auth/test 2>/dev/null || echo "❌ Endpoint não existe (normal)"
echo ""

echo "✅ URLs configuradas no Flutter:"
echo "   - Web: http://localhost:3000/api"
echo "   - iOS: http://$CURRENT_IP:3000/api"
echo "   - Android: http://$CURRENT_IP:3000/api"
echo "   - Desktop: http://localhost:3000/api"
