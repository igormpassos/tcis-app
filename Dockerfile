# Dockerfile para Flutter Web com build completo
FROM ubuntu:22.04 as builder

# Instalar dependências
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Instalar Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

# Configurar Flutter
RUN flutter doctor -v
RUN flutter config --enable-web

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

# Copiar configuração nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Iniciar nginx
CMD ["nginx", "-g", "daemon off;"]
