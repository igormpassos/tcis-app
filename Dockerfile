# DOCKERFILE ESTÁTICO - USE APENAS APÓS flutter build web
# Execute: ./build-static.sh antes de fazer o deploy
FROM nginx:alpine

# Copiar arquivos web pré-construídos
COPY build/web /usr/share/nginx/html

# Copiar configuração nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Iniciar nginx
CMD ["nginx", "-g", "daemon off;"]
