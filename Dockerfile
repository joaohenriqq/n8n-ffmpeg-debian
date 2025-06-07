FROM node:20-bookworm-slim

# Etapa 1: Instala dependências do sistema (inclui Python 3.8 para o Gentle)
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    frei0r-plugins \
    ladspa-sdk \
    lv2-dev \
    dragonfly-reverb-lv2 \
    calf-plugins \
    lv2file \
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
    python3.8 \
    python3.8-venv \
    python3.8-dev \
    python3-pip \
    python3-venv \
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
    automake \
    autoconf \
    libtool \
    subversion \
    zlib1g-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa X: Atualiza pip/setuptools para Python 3.8 e instala Gentle em ambiente próprio
RUN python3.8 -m pip install --upgrade pip setuptools
RUN git clone --recurse-submodules https://github.com/lowerquality/gentle.git /opt/gentle
WORKDIR /opt/gentle
RUN python3.8 ./install.py  # usa o Python 3.8 para instalar dependências do Gentle
RUN ln -sf /usr/bin/python3.8 /usr/local/bin/python3.8

# (Opcional) Atalho para rodar o servidor Gentle no Python 3.8
RUN echo '#!/bin/bash\nexec python3.8 /opt/gentle/serve.py --port 8765 "$@"' > /usr/local/bin/gentle-server && chmod +x /usr/local/bin/gentle-server

# Etapa Y: Define a variável de ambiente para o diretório de recursos do Gentle
ENV GENTLE_RESOURCES_ROOT=/opt/gentle/exp

# Etapa 3: Atualiza o pip global para evitar warnings
RUN python3 -m pip install --upgrade pip --break-system-packages

# Etapa 4: Instala pysrt direto no Python do sistema
RUN pip3 install pysrt --break-system-packages

# Etapa 5: Instala FFmpeg mais recente via build oficial do BtbN (master)
RUN mkdir -p /opt/ffmpeg && \
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 3 -qO- \
      https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-linux64-gpl-shared.tar.xz | \
    tar -xJ --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe

ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:$LD_LIBRARY_PATH

# Etapa 6: Compila e instala ImageMagick 7 com suporte a magick e módulos
RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz && \
    tar xvzf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --with-modules --with-perl --enable-hdri --with-rsvg && \
    make -j$(nproc) && make install && ldconfig && \
    cd .. && rm -rf ImageMagick*

# Etapa 7: Instala ferramentas Python com pipx (modo seguro com system-site-packages)
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_HOME=/opt/pipx
RUN pipx install ffmpeg-normalize --system-site-packages && \
    pipx install 'git+https://github.com/m1guelpf/auto-subtitle.git' --system-site-packages && \
    pipx inject auto-subtitle ffmpeg-python && \
    ln -sf /opt/pipx/venvs/auto-subtitle/bin/auto_subtitle /usr/local/bin/auto_subtitle

# Etapa 8: Clona e instala PupCaps
RUN git clone https://github.com/hosuaby/PupCaps.git /opt/pupcaps && \
    cd /opt/pupcaps && \
    npm install && \
    npm install -g .

# Etapa 9: Instala o n8n globalmente
RUN npm install -g n8n

# Etapa 10: Instala o JSON5 globalmente
RUN npm install -g json5

# Etapa 11: Define diretório de trabalho
WORKDIR /data

# Etapa 12: Define usuário e porta do n8n
USER node
EXPOSE 5678
ENV N8N_PORT=5678

# Etapa 13: Inicia o n8n (gentle pode ser rodado à parte, ver abaixo)
CMD ["n8n"]
