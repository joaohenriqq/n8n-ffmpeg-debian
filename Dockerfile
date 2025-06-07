FROM node:20-bookworm-slim

# Instala dependências de sistema para build, runtime e MFA (_kalpy/Kaldi)
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
    python3-dev \
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
    # DEPENDÊNCIAS MFA/Kaldi _kalpy_
    libatlas-base-dev \
    libsndfile1 \
    libopenblas-dev \
    liblapack-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Atualiza o pip global (Python do sistema) para evitar warnings
RUN python3 -m pip install --upgrade pip --break-system-packages

# Instala o Montreal Forced Aligner (MFA) de forma isolada com pipx (recomendado)
RUN pipx install montreal-forced-aligner

# Adiciona o pipx e binários no PATH global
ENV PATH="/root/.local/bin:/root/.local/pipx/venvs/montreal-forced-aligner/bin:${PATH}"

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

# Inicia o n8n (Gentle ou MFA podem ser rodados à parte, via comando manual/n8n)
CMD ["n8n"]
