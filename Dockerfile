# ────────────────────────────────────────────────────────────────────────────────
# n8n (Node 20) + utilitários multimídia + kit de fontes multilíngue + display
# ────────────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim

# ─── 1. Pacotes base ───────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential curl git jq sox ghostscript tesseract-ocr mediainfo \
        python3 python3-dev python3-pip python3-venv \
        libffi-dev libssl-dev libxml2-dev libjpeg-dev libpng-dev \
        libtiff-dev libopenjp2-7-dev libwebp-dev zlib1g-dev \
        unzip wget zip \
        imagemagick graphicsmagick \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── 1-bis. Fontes multilíngues + display para thumbnails ──────────────────────
RUN set -eux; \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        fontconfig \
        fonts-noto-core fonts-noto-cjk \
        fonts-dejavu-core fonts-dejavu-extra \
        fonts-roboto fonts-liberation2 fonts-freefont-ttf \
    && mkdir -p /usr/local/share/fonts/truetype/gf && \
    cd /usr/local/share/fonts/truetype/gf && \
    # Baixa famílias display que não existem no repo stable
    for f in Anton BebasNeue Bangers LuckiestGuy LilitaOne \
             Oswald LeagueSpartan Rowdies Teko ; do \
        curl -fsSL "https://raw.githubusercontent.com/google/fonts/main/ofl/${f,,}/${f}-Regular.ttf" \
          -o "${f}-Regular.ttf"; \
    done && \
    # Actualiza cache de fontes
    fc-cache -f -v && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── 2. Bibliotecas Python (textgrid, pysrt etc.) ──────────────────────────────
RUN python3 -m pip install --upgrade pip --break-system-packages && \
    pip3 install --break-system-packages pysrt textgrid ffsubsync pysubs2

# ─── 3. FFmpeg build BtbN ───────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends file && rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/ffmpeg && \
    wget -O /tmp/ffmpeg.tar.xz \
      https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl-shared.tar.xz && \
    tar -xJf /tmp/ffmpeg.tar.xz --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe
ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:${LD_LIBRARY_PATH:-}

# ─── 4. n8n + extras via npm ───────────────────────────────────────────────────
RUN npm install -g n8n json5

# ─── 5. Script tg2srt ──────────────────────────────────────────────────────────
RUN set -e && \
cat > /usr/local/bin/tg2srt <<'PY' && \
chmod +x /usr/local/bin/tg2srt
#!/usr/bin/env python3
# (conteúdo original inalterado)
PY

# ─── 6. Usuário não-root & diretório de trabalho ───────────────────────────────
WORKDIR /data
USER node

# ─── 7. Porta / CMD ────────────────────────────────────────────────────────────
EXPOSE 5678
ENV N8N_PORT=5678
CMD ["n8n"]
