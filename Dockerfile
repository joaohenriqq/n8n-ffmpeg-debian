# ────────────────────────────────────────────────────────────────────────────────
# n8n (Node 20) + FFmpeg + ImageMagick/GraphicsMagick + kit de fontes multilíngues
# e display de alto impacto + utilitários Python + script tg2srt
# ────────────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim

# Use bash em todos os RUN (necessário para ${var,,})
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# ────────────────────────────────────────────────────────────────────────────────
# 1. Pacotes base do sistema
# ────────────────────────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential curl git jq sox ghostscript tesseract-ocr mediainfo \
      python3 python3-dev python3-pip python3-venv \
      libffi-dev libssl-dev libxml2-dev libjpeg-dev libpng-dev \
      libtiff-dev libopenjp2-7-dev libwebp-dev zlib1g-dev \
      unzip wget zip \
      imagemagick graphicsmagick && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ────────────────────────────────────────────────────────────────────────────────
# 1-bis. Fontes multilíngues + display (alto CTR) para thumbnails
# ────────────────────────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      fontconfig \
      fonts-noto-core fonts-noto-cjk \
      fonts-dejavu-core fonts-dejavu-extra \
      fonts-roboto fonts-liberation2 fonts-freefont-ttf && \
    mkdir -p /usr/local/share/fonts/truetype/gf && \
    cd /usr/local/share/fonts/truetype/gf && \
    for f in Anton BebasNeue Bangers LuckiestGuy LilitaOne Oswald LeagueSpartan Rowdies Teko; do \
      curl -fsSL "https://raw.githubusercontent.com/google/fonts/master/ofl/${f,,}/${f}-Regular.ttf" \
        -o "${f}-Regular.ttf"; \
    done && \
    fc-cache -f -v && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ────────────────────────────────────────────────────────────────────────────────
# 2. Bibliotecas Python (TextGrid, legendas, sync)
# ────────────────────────────────────────────────────────────────────────────────
RUN python3 -m pip install --upgrade pip --break-system-packages && \
    pip3 install --break-system-packages pysrt textgrid ffsubsync pysubs2

# ────────────────────────────────────────────────────────────────────────────────
# 3. FFmpeg (build BtbN)
# ────────────────────────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends file && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/ffmpeg && \
    wget -O /tmp/ffmpeg.tar.xz \
      https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl-shared.tar.xz && \
    tar -xJf /tmp/ffmpeg.tar.xz --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg  /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe
ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:${LD_LIBRARY_PATH:-}

# ────────────────────────────────────────────────────────────────────────────────
# 4. n8n + extras via npm
# ────────────────────────────────────────────────────────────────────────────────
RUN npm install -g n8n json5

# ────────────────────────────────────────────────────────────────────────────────
# 5. Script tg2srt em /usr/local/bin
# ────────────────────────────────────────────────────────────────────────────────
RUN cat > /usr/local/bin/tg2srt <<'PY' && \
    chmod +x /usr/local/bin/tg2srt
#!/usr/bin/env python3
import sys, pathlib, textgrid, pysrt
if len(sys.argv) != 3:
    sys.exit("Uso: tg2srt IN.TextGrid OUT.srt")
inp, outp = map(pathlib.Path, sys.argv[1:3])
tg   = textgrid.TextGrid.fromFile(inp)
tier = next(t for t in tg.tiers if t.name.lower().startswith("word"))
subs = pysrt.SubRipFile()
for idx, iv in enumerate(tier.intervals, 1):
    txt = iv.mark.strip()
    if not txt:
        continue
    subs.append(
        pysrt.SubRipItem(
            index=idx,
            start=pysrt.SubRipTime(milliseconds=int(iv.minTime * 1000)),
            end=pysrt.SubRipTime(milliseconds=int(iv.maxTime * 1000)),
            text=txt,
        )
    )
subs.save(outp, encoding="utf-8")
print(f"SRT salvo em {outp}  •  {len(subs)} linhas")
PY

# ────────────────────────────────────────────────────────────────────────────────
# 6. Usuário não-root + diretório padrão
# ────────────────────────────────────────────────────────────────────────────────
WORKDIR /data
USER node

# ────────────────────────────────────────────────────────────────────────────────
# 7. Porta e comando padrão
# ────────────────────────────────────────────────────────────────────────────────
EXPOSE 5678
ENV N8N_PORT=5678
CMD ["n8n"]
