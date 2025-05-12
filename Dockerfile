# Etapa 1: Imagem base Debian slim
FROM debian:bullseye-slim

# Etapa 2: Instala dependências e ferramentas necessárias
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

# Etapa 3: Define o usuário padrão
USER node
