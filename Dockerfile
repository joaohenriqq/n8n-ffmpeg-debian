# Etapa 1: Imagem base Debian com Node.js
FROM node:18-bullseye-slim

# Etapa 2: Instala dependências e ferramentas auxiliares
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    frei0r-plugins \
    ladspa-sdk \
    rubberband-cli \
    imagemagick \
    tesseract-ocr \
    curl \
    wget \
    zip \
    unzip \
    tar \
    jq \
    openssh-client \
    fontconfig \
    libfreetype6 \
    libass9 \
    libharfbuzz-dev \
    libfribidi-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa 3: Instala o n8n globalmente
RUN npm install -g n8n

# Etapa 4: Define diretório de trabalho
WORKDIR /data

# Etapa 5: Expõe a porta 80 (como já está sendo usada no Easypanel)
EXPOSE 80

# Etapa 6: Define o usuário padrão
USER node

# Etapa 7: Inicia o n8n
CMD ["n8n"]
