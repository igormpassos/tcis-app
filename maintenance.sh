#!/bin/bash

# Scripts de manutenção para TCIS App em produção

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para mostrar status
show_status() {
    echo -e "${BLUE}🔍 Status dos Containers:${NC}"
    docker-compose ps
    echo ""
}

# Função para mostrar logs
show_logs() {
    service=${1:-""}
    if [ -z "$service" ]; then
        echo -e "${BLUE}📋 Logs de todos os serviços:${NC}"
        docker-compose logs --tail=50 -f
    else
        echo -e "${BLUE}📋 Logs do serviço $service:${NC}"
        docker-compose logs --tail=50 -f "$service"
    fi
}

# Função para backup do banco
backup_database() {
    timestamp=$(date +%Y%m%d_%H%M%S)
    backup_file="tcis_backup_${timestamp}.sql"
    
    echo -e "${YELLOW}💾 Criando backup do banco de dados...${NC}"
    docker-compose exec -T postgres pg_dump -U postgres -d tcis_db > "$backup_file"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup criado: $backup_file${NC}"
        
        # Comprimir backup
        gzip "$backup_file"
        echo -e "${GREEN}🗜️  Backup comprimido: ${backup_file}.gz${NC}"
    else
        echo -e "${RED}❌ Erro ao criar backup!${NC}"
    fi
}

# Função para restaurar backup
restore_database() {
    backup_file=$1
    
    if [ -z "$backup_file" ]; then
        echo -e "${RED}❌ Especifique o arquivo de backup!${NC}"
        echo "Uso: $0 restore <arquivo.sql>"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}❌ Arquivo de backup não encontrado: $backup_file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}⚠️  Isso irá SUBSTITUIR todos os dados atuais!${NC}"
    read -p "Tem certeza? (digite 'CONFIRMO'): " confirm
    
    if [ "$confirm" = "CONFIRMO" ]; then
        echo -e "${YELLOW}🔄 Restaurando backup...${NC}"
        
        # Se for arquivo .gz, descomprimir primeiro
        if [[ "$backup_file" == *.gz ]]; then
            gunzip -c "$backup_file" | docker-compose exec -T postgres psql -U postgres -d tcis_db
        else
            docker-compose exec -T postgres psql -U postgres -d tcis_db < "$backup_file"
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Backup restaurado com sucesso!${NC}"
        else
            echo -e "${RED}❌ Erro ao restaurar backup!${NC}"
        fi
    else
        echo -e "${YELLOW}❌ Restauração cancelada.${NC}"
    fi
}

# Função para atualizar aplicação
update_app() {
    echo -e "${YELLOW}🔄 Atualizando aplicação...${NC}"
    
    # Fazer backup antes da atualização
    echo -e "${BLUE}1. Criando backup de segurança...${NC}"
    backup_database
    
    # Pull das mudanças (se for repositório git)
    if [ -d ".git" ]; then
        echo -e "${BLUE}2. Atualizando código...${NC}"
        git pull origin main
    fi
    
    # Rebuild e restart
    echo -e "${BLUE}3. Rebuilding containers...${NC}"
    docker-compose up -d --build
    
    # Executar migrações
    echo -e "${BLUE}4. Executando migrações...${NC}"
    docker-compose exec backend npx prisma migrate deploy
    
    echo -e "${GREEN}✅ Atualização concluída!${NC}"
}

# Função para limpar recursos
cleanup() {
    echo -e "${YELLOW}🧹 Limpando recursos desnecessários...${NC}"
    
    # Remover containers parados
    docker container prune -f
    
    # Remover imagens não utilizadas
    docker image prune -f
    
    # Remover volumes órfãos
    docker volume prune -f
    
    # Remover networks não utilizadas
    docker network prune -f
    
    echo -e "${GREEN}✅ Limpeza concluída!${NC}"
}

# Função para monitoramento
monitor() {
    echo -e "${BLUE}📊 Monitoramento do sistema:${NC}"
    echo ""
    
    # Status dos containers
    show_status
    
    # Uso de recursos
    echo -e "${BLUE}💽 Uso de disco:${NC}"
    df -h /
    echo ""
    
    echo -e "${BLUE}🧠 Uso de memória:${NC}"
    free -h
    echo ""
    
    echo -e "${BLUE}🔥 Uso de CPU:${NC}"
    top -b -n1 | head -5
    echo ""
    
    # Status dos serviços
    echo -e "${BLUE}🌐 Testando conectividade:${NC}"
    if curl -s http://localhost:3000/health > /dev/null; then
        echo -e "${GREEN}✅ Backend API: OK${NC}"
    else
        echo -e "${RED}❌ Backend API: FALHA${NC}"
    fi
    
    if curl -s http://localhost:80 > /dev/null; then
        echo -e "${GREEN}✅ Frontend: OK${NC}"
    else
        echo -e "${RED}❌ Frontend: FALHA${NC}"
    fi
}

# Função para mostrar ajuda
show_help() {
    echo -e "${BLUE}🛠️  TCIS App - Scripts de Manutenção${NC}"
    echo ""
    echo "Uso: $0 [comando] [opções]"
    echo ""
    echo "Comandos disponíveis:"
    echo "  status                 - Mostrar status dos containers"
    echo "  logs [serviço]         - Mostrar logs (todos ou de um serviço específico)"
    echo "  backup                 - Criar backup do banco de dados"
    echo "  restore <arquivo>      - Restaurar backup do banco de dados"
    echo "  update                 - Atualizar aplicação completa"
    echo "  cleanup               - Limpar recursos desnecessários do Docker"
    echo "  monitor               - Monitorar sistema e serviços"
    echo "  restart [serviço]      - Reiniciar containers"
    echo "  help                  - Mostrar esta ajuda"
    echo ""
    echo "Exemplos:"
    echo "  $0 status"
    echo "  $0 logs backend"
    echo "  $0 backup"
    echo "  $0 restore tcis_backup_20240819_150000.sql.gz"
    echo ""
}

# Função para restart
restart_services() {
    service=${1:-""}
    if [ -z "$service" ]; then
        echo -e "${YELLOW}🔄 Reiniciando todos os serviços...${NC}"
        docker-compose restart
    else
        echo -e "${YELLOW}🔄 Reiniciando serviço: $service...${NC}"
        docker-compose restart "$service"
    fi
    echo -e "${GREEN}✅ Restart concluído!${NC}"
}

# Main script
case "$1" in
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "backup")
        backup_database
        ;;
    "restore")
        restore_database "$2"
        ;;
    "update")
        update_app
        ;;
    "cleanup")
        cleanup
        ;;
    "monitor")
        monitor
        ;;
    "restart")
        restart_services "$2"
        ;;
    "help"|"")
        show_help
        ;;
    *)
        echo -e "${RED}❌ Comando não reconhecido: $1${NC}"
        show_help
        exit 1
        ;;
esac
