FROM node:20-bookworm-slim

# ============ SISTEMA & BUILD ESSENTIALS =============
RUN apt-get update && apt-get install -y --no-install-recommends \
    bc \
    build-essential \
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
    git \
    curl \
    wget \
    zip \
    unzip \
    tar \
    jq \
    sudo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============ LIBS PARA MFA, KALDI, AUDIO, VIDEO, ETC ===========
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    pipx \
    frei0r-plugins \
    ladspa-sdk \
    lv2-dev \
    dragonfly-reverb-lv2 \
    calf-plugins \
    lv2file \
    rubberband-cli \
    tesseract-ocr \
    ghostscript \
    mediainfo \
    libimage-exiftool-perl \
    sox \
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
    # MFA/Kaldi _kalpy_ específicas:
    libatlas-base-dev \
    libsndfile1 \
    libopenblas-dev \
    liblapack-dev \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ============ PYTHON GLOBAL: pip e pysrt ===========
RUN python3 -m pip install --upgrade pip --break-system-packages && \
    pip3 install pysrt --break-system-packages

# ============ MONTREAL FORCED ALIGNER (MFA) ===========
RUN pipx install montreal-forced-aligner

# Permissões e PATH globais para MFA funcionar em qualquer user/contexto
RUN chmod -R a+rx /root/.local /usr/local/bin /opt/pipx
ENV PATH="/root/.local/bin:/opt/pipx/bin:/opt/pipx/venvs/montreal-forced-aligner/bin:${PATH}"
RUN ln -sf /root/.local/bin/mfa /usr/local/bin/mfa

# Teste do MFA logo no build (fail fast)
RUN /usr/local/bin/mfa --version

# ============ FFMPEG LATEST (BtbN build oficial) ===========
RUN mkdir -p /opt/ffmpeg && \
    wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 3 -qO- \
      https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-linux64-gpl-shared.tar.xz | \
    tar -xJ --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe

ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:$LD_LIBRARY_PATH

# ============ IMAGEMAGICK 7 ===========
RUN wget https://imagemagick.org/archive/ImageMagick.tar.gz && \
    tar xvzf ImageMagick.tar.gz && \
    cd ImageMagick-* && \
    ./configure --with-modules --with-perl --enable-hdri --with-rsvg && \
    make -j$(nproc) && make install && ldconfig && \
    cd .. && rm -rf ImageMagick*

# ============ PIPX FERRAMENTAS ÚTEIS ===========
ENV PIPX_BIN_DIR=/usr/local/bin
ENV PIPX_HOME=/opt/pipx
RUN pipx install ffmpeg-normalize --system-site-packages && \
    pipx install 'git+https://github.com/m1guelpf/auto-subtitle.git' --system-site-packages && \
    pipx inject auto-subtitle ffmpeg-python && \
    ln -sf /opt/pipx/venvs/auto-subtitle/bin/auto_subtitle /usr/local/bin/auto_subtitle

# ============ PUPCABS ===========
RUN git clone https://github.com/hosuaby/PupCaps.git /opt/pupcaps && \
    cd /opt/pupcaps && \
    npm install && \
    npm install -g .

# ============ n8n E JSON5 ===========
RUN npm install -g n8n
RUN npm install -g json5

# ============ FINAL ===========
WORKDIR /data
USER node
EXPOSE 5678
ENV N8N_PORT=5678
CMD ["n8n"]
