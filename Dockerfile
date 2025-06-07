FROM node:20-bookworm-slim

# Etapa 1: Instala dependências do sistema (SEM python3.8 via apt, só o básico para build e runtime)
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
    python3 \
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
    libssl-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libreadline-dev \
    libsqlite3-dev \
    libgdbm-dev \
    libdb5.3-dev \
    libbz2-dev \
    libexpat1-dev \
    liblzma-dev \
    tk-dev \
    libffi-dev \
    uuid-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Etapa 2: Baixa, compila e instala Python 3.8.19 manualmente
RUN cd /usr/src && \
    wget https://www.python.org/ftp/python/3.8.19/Python-3.8.19.tgz && \
    tar xzf Python-3.8.19.tgz && \
    cd Python-3.8.19 && \
    ./configure --enable-optimizations --with-ensurepip=install && \
    make -j$(nproc) && make altinstall && \
    cd / && rm -rf /usr/src/Python-3.8.19*

# Etapa 3: Atualiza pip/setuptools/wheel para Python 3.8
RUN /usr/local/bin/python3.8 -m pip install --upgrade pip setuptools wheel

RUN git clone --recurse-submodules https://github.com/lowerquality/gentle.git /opt/gentle
WORKDIR /opt/gentle
RUN ./install.sh

# Atalho para rodar o servidor Gentle no Python 3.8
RUN echo '#!/bin/bash\nexec /usr/local/bin/python3.8 /opt/gentle/serve.py --port 8765 "$@"' > /usr/local/bin/gentle-server && chmod +x /usr/local/bin/gentle-server

# Variável de ambiente para o Gentle
ENV GENTLE_RESOURCES_ROOT=/opt/gentle/exp

# Atualiza o pip global (Python do sistema) para evitar warnings
RUN python3 -m pip install --upgrade pip --break-system-packages

# Instala pysrt direto no Python do sistema
RUN pip3 install pysrt --break-system-packages

# Instala FFmpeg mais recente via build oficial do BtbN (master)
RUN mkdir -p /opt/ffmpeg && \
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 3 -qO- \
      https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-linux64-gpl-shared.tar.xz | \
    tar -xJ --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe

ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:$LD_LIBRARY_PATH

# Compila e instala ImageMagick 7 com suporte a magick e módulos
RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz && \
    tar xvzf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --with-modules --with-perl --enable-hdri --with-rsvg && \
    make -j$(nproc) && make install && ldconfig && \
    cd .. && rm -rf ImageMagick*

# Instala ferramentas Python com pipx (modo seguro com system-site-packages)
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_HOME=/opt/pipx
RUN pipx install ffmpeg-normalize --system-site-packages && \
    pipx install 'git+https://github.com/m1guelpf/auto-subtitle.git' --system-site-packages && \
    pipx inject auto-subtitle ffmpeg-python && \
    ln -sf /opt/pipx/venvs/auto-subtitle/bin/auto_subtitle /usr/local/bin/auto_subtitle

# Clona e instala PupCaps
RUN git clone https://github.com/hosuaby/PupCaps.git /opt/pupcaps && \
    cd /opt/pupcaps && \
    npm install && \
    npm install -g .

# Instala o n8n globalmente
RUN npm install -g n8n

# Instala o JSON5 globalmente
RUN npm install -g json5

# Define diretório de trabalho
WORKDIR /data

# Define usuário e porta do n8n
USER node
EXPOSE 5678
ENV N8N_PORT=5678

# Inicia o n8n (Gentle pode ser rodado à parte: gentle-server)
CMD ["n8n"]
