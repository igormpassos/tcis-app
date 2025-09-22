# Dockerfile para Flutter Web com build completo
FROM ubuntu:22.04 AS builder

# Evitar prompts interativos
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    ca-certificates \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Criar usuário não-root para Flutter
RUN useradd -m -s /bin/bash flutter
USER flutter
WORKDIR /home/flutter

# Instalar Flutter usando versão específica estável
ENV FLUTTER_HOME="/home/flutter/flutter"
ENV PATH="$FLUTTER_HOME/bin:$PATH"

RUN git clone https://github.com/flutter/flutter.git -b stable --depth 1 $FLUTTER_HOME

# Pré-download das dependências Flutter
RUN flutter doctor
RUN flutter config --enable-web
RUN flutter precache --web

# Copiar arquivos do projeto
WORKDIR /home/flutter/app
COPY --chown=flutter:flutter pubspec.yaml ./
RUN flutter pub get

COPY --chown=flutter:flutter . .

# Build para web
RUN flutter build web --release

# Estágio de produção com nginx
FROM nginx:alpine
COPY --from=builder /home/flutter/app/build/web /usr/share/nginx/html

# Copiar configuração nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta 80
EXPOSE 80

# Iniciar nginx
CMD ["nginx", "-g", "daemon off;"]
