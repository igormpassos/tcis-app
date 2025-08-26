-- Inicialização do banco de dados
-- Este arquivo é executado automaticamente quando o container PostgreSQL é criado

-- Criar extensões úteis
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Definir timezone
SET timezone = 'America/Sao_Paulo';
