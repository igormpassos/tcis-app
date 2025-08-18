#!/bin/bash

# Script para obter o IP da máquina
IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
PORT=${PORT:-3000}

echo "🌐 IP atual da máquina: $IP"
echo "🚀 Backend disponível em:"
echo "   - Local: http://localhost:$PORT"
echo "   - Rede: http://$IP:$PORT"
echo "   - Health check: http://$IP:$PORT/health"
