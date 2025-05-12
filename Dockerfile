FROM node:18-bullseye-slim

# Etapa 1: Instala dependências do sistema
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
    python3 \
    python3-pip \
    git \
    mediainfo \
    libimage-exiftool-perl \
    sox \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa 2: Instala pacotes Python via pip
RUN pip install --upgrade pip && \
    pip install \
      openai-whisper \
      git+https://github.com/m1guelpf/auto-subtitle.git \
      ffmpeg-normalize

# Etapa 3: Clona e instala PupCaps
RUN git clone https://github.com/hosuaby/PupCaps.git /opt/pupcaps && \
    cd /opt/pupcaps && \
    npm install && \
    npm install -g .

# Etapa 4: Instala o n8n globalmente
RUN npm install -g n8n

# Etapa 5: Define diretório de trabalho
WORKDIR /data

# Etapa 6: Define usuário e porta
USER node
EXPOSE 5678
ENV N8N_PORT=5678

# Etapa 7: Inicia o n8n
CMD ["n8n"]
