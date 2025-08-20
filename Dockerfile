# Dockerfile principal para o frontend Flutter Web
FROM cirrusci/flutter:3.19.6 as builder

# Configurar Flutter para web
RUN flutter config --enable-web --no-analytics
RUN flutter precache --web

# Copiar código Flutter
WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build para web
RUN flutter build web --release

# Estágio de produção com nginx
FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html

# Configuração personalizada do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
