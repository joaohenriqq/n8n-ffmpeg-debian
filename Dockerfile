FROM node:20-bookworm-slim

# Etapa 1: Instala dependências do sistema (exceto ffmpeg, que será instalado via build oficial)
RUN apt-get update && apt-get install -y --no-install-recommends \
    frei0r-plugins \
    ladspa-sdk \
    rubberband-cli \
    tesseract-ocr \
    ghostscript \
    curl \
    wget \
    zip \
    unzip \
    tar \
    jq \
    git \
    python3 \
    python3-pip \
    pipx \
    mediainfo \
    libimage-exiftool-perl \
    sox \
    build-essential \
    fontconfig \
    libfreetype6 \
    libass9 \
    libharfbuzz-dev \
    libfribidi-dev \
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
    libltdl-dev \
    libx11-dev \
    libxt-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa 2: Instala FFmpeg mais recente via build oficial do BtbN (master)
RUN mkdir -p /opt/ffmpeg && \
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 3 -qO- \
      https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-linux64-gpl-shared.tar.xz | \
    tar -xJ --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe

# Corrige carregamento das libs compartilhadas do FFmpeg
ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:$LD_LIBRARY_PATH

# Etapa 3: Compila e instala ImageMagick 7 com suporte a magick e módulos
RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz && \
    tar xvzf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --with-modules --with-perl --enable-hdri --with-rsvg && \
    make -j$(nproc) && make install && ldconfig && \
    cd .. && rm -rf ImageMagick*

# Etapa 4: Instala ferramentas Python com pipx (modo seguro com system-site-packages)
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_HOME=/opt/pipx
RUN pipx install openai-whisper --system-site-packages && \
    pipx install ffmpeg-normalize --system-site-packages && \
    pipx install 'git+https://github.com/m1guelpf/auto-subtitle.git' --system-site-packages && \
    pipx inject auto-subtitle ffmpeg-python && \
    ln -sf /opt/pipx/venvs/auto-subtitle/bin/auto_subtitle /usr/local/bin/auto_subtitle

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
