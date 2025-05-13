FROM node:20-bookworm-slim

# Etapa 1: Instala dependências do sistema
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    frei0r-plugins \
    ladspa-sdk \
    rubberband-cli \
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
    python3-venv \
    git \
    mediainfo \
    libimage-exiftool-perl \
    sox \
    build-essential \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    libwebp-dev \
    libheif-dev \
    libopenjp2-7-dev \
    libxml2-dev \
    liblcms2-dev \
    libraw-dev \
    libfftw3-dev \
    libopenexr-dev \
    librsvg2-dev \
    ghostscript \
    libltdl-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa 2: Instala o ImageMagick 7 a partir do código-fonte
RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz && \
    tar xvzf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --with-modules --enable-hdri --with-rsvg && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd .. && rm -rf ImageMagick*

# Etapa 3: Cria e ativa um ambiente virtual Python isolado
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Etapa 4: Instala os pacotes Python no ambiente isolado
RUN pip install --upgrade pip && \
    pip install \
      openai-whisper \
      git+https://github.com/m1guelpf/auto-subtitle.git \
      ffmpeg-normalize

# Etapa 5: Clona e instala PupCaps
RUN git clone https://github.com/hosuaby/PupCaps.git /opt/pupcaps && \
    cd /opt/pupcaps && \
    npm install && \
    npm install -g .

# Etapa 6: Instala o n8n globalmente
RUN npm install -g n8n

# Etapa 7: Define diretório de trabalho
WORKDIR /data

# Etapa 8: Define usuário e porta
USER node
EXPOSE 5678
ENV N8N_PORT=5678

# Etapa 9: Inicia o n8n
CMD ["n8n"]
