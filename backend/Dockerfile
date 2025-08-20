# Use Node.js oficial como base
FROM node:18-alpine

# Instalar dependências do sistema necessárias
RUN apk add --no-cache \
    postgresql-client \
    curl

# Criar diretório de trabalho
WORKDIR /app

# Copiar package.json e package-lock.json (se existir)
COPY package*.json ./

# Instalar dependências
RUN npm ci --only=production

# Copiar código da aplicação
COPY . .

# Gerar cliente do Prisma
RUN npx prisma generate

# Criar diretório para uploads
RUN mkdir -p uploads && chmod 755 uploads

# Expor a porta
EXPOSE 3000

# Criar script de inicialização
RUN echo '#!/bin/sh\necho "Running migrations..."\nnpx prisma migrate deploy\necho "Starting server..."\nnode server.js' > start.sh && chmod +x start.sh

# Comando para iniciar a aplicação
CMD ["./start.sh"]
