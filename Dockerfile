# ────────────────────────────────────────────────────────────────────────────────
# n8n + utilitários multimídia + tg2srt
# ────────────────────────────────────────────────────────────────────────────────
FROM node:20-bookworm-slim

# ────────────────────────────────────────────────────────────────────────────────
# 1. Sistema & dependências nativas
# ────────────────────────────────────────────────────────────────────────────────
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        automake autoconf bc build-essential curl git jq sox \
        ghostscript tesseract-ocr mediainfo fontconfig libsndfile1 \
        python3 python3-dev python3-pip python3-venv \
        libssl-dev libffi-dev libxml2-dev libjpeg-dev libpng-dev \
        libtiff-dev libopenjp2-7-dev libwebp-dev zlib1g-dev \
        unzip wget zip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ────────────────────────────────────────────────────────────────────────────────
# 2. Python: atualiza pip + instala libs usadas pelos scripts
# ────────────────────────────────────────────────────────────────────────────────
RUN python3 -m pip install --upgrade pip --break-system-packages && \
    pip3 install --break-system-packages \
        pysrt \
        textgrid

# ────────────────────────────────────────────────────────────────────────────────
# 3. Instala FFmpeg (build BtbN)  +  ImageMagick (opcional)
# ────────────────────────────────────────────────────────────────────────────────
RUN mkdir -p /opt/ffmpeg && \
    wget -qO- \
      https://github.com/BtbN/FFmpeg-Builds/releases/latest/download/ffmpeg-master-latest-linux64-gpl-shared.tar.xz \
    | tar -xJ --strip-components=1 -C /opt/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffmpeg  /usr/local/bin/ffmpeg && \
    ln -sf /opt/ffmpeg/bin/ffprobe /usr/local/bin/ffprobe

ENV LD_LIBRARY_PATH=/opt/ffmpeg/lib:$LD_LIBRARY_PATH

# ────────────────────────────────────────────────────────────────────────────────
# 4. Instala n8n  +  utils (auto_subtitle, ﻿ffmpeg-normalize, PupCaps)  via npm/pipx
# ────────────────────────────────────────────────────────────────────────────────
RUN npm install -g n8n json5

# (Exemplo de instalação de outros utilitários — pode comentar se não usar)
RUN pip install --break-system-packages ffmpeg-normalize

# ────────────────────────────────────────────────────────────────────────────────
# 5. Adiciona script *tg2srt* (TextGrid → SRT)
# ────────────────────────────────────────────────────────────────────────────────
RUN cat > /usr/local/bin/tg2srt << 'PY' && chmod +x /usr/local/bin/tg2srt
#!/usr/bin/env python3
"""
tg2srt — converte TextGrid (tier 'word') em legenda SRT.

Uso:
    tg2srt input.TextGrid output.srt
"""
import sys, textgrid, pysrt, pathlib

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
# 6. Diretório de trabalho  +  usuário n8n
# ────────────────────────────────────────────────────────────────────────────────
WORKDIR /data
USER node

# ────────────────────────────────────────────────────────────────────────────────
# 7. Porta / entrypoint
# ────────────────────────────────────────────────────────────────────────────────
EXPOSE 5678
ENV N8N_PORT=5678
CMD ["n8n"]
