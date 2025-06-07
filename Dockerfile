FROM node:20-bookworm-slim

# Instala dependências do sistema (build, runtime, MFA/Kaldi, ferramentas de mídia e OCR)
RUN apt-get update && apt-get install -y --no-install-recommends \
    automake \
    autoconf \
    bc \
    build-essential \
    calf-plugins \
    curl \
    dragonfly-reverb-lv2 \
    fontconfig \
    frei0r-plugins \
    ghostscript \
    git \
    jq \
    ladspa-sdk \
    libass9 \
    libatlas-base-dev \
    libbz2-dev \
    libc6-dev \
    libc-dev \
    libdb5.3-dev \
    libexpat1-dev \
    libffi-dev \
    libfreetype6 \
    libfribidi-dev \
    libgdbm-dev \
    libharfbuzz-dev \
    libheif-dev \
    libimage-exiftool-perl \
    libjpeg-dev \
    liblapack-dev \
    liblcms2-dev \
    libltdl-dev \
    liblzma-dev \
    libncurses5-dev \
    libncursesw5-dev \
    libopenblas-dev \
    libopenexr-dev \
    libopenjp2-7-dev \
    libpng-dev \
    libraw-dev \
    libreadline-dev \
    librsvg2-dev \
    libsndfile1 \
    libsqlite3-dev \
    libssl-dev \
    libtiff-dev \
    libtool \
    libwebp-dev \
    libx11-dev \
    libxt-dev \
    libxml2-dev \
    libfftw3-dev \
    lv2-dev \
    lv2file \
    mediainfo \
    pipx \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    rubberband-cli \
    sox \
    subversion \
    tar \
    tesseract-ocr \
    tk-dev \
    unzip \
    uuid-dev \
    wget \
    zip \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Atualiza o pip global (Python do sistema) para evitar warnings
RUN python3 -m pip install --upgrade pip --break-system-packages

# Cria o diretório para o pipx antes de qualquer uso
RUN mkdir -p /opt/pipx

# Instala Montreal Forced Aligner (MFA) via pipx (isolado, robusto)
RUN pipx install montreal-forced-aligner

# Permissões e PATH globais para MFA funcionar em qualquer usuário/contexto
RUN chmod -R a+rx /root/.local /usr/local/bin /opt/pipx
ENV PATH="/root/.local/bin:/opt/pipx/bin:/opt/pipx/venvs/montreal-forced-aligner/bin:${PATH}"
RUN ln -sf /root/.local/bin/mfa /usr/local/bin/mfa

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
