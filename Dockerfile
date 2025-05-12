FROM node:18-bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    frei0r-plugins \
    ladspa-sdk \
    rubberband-cli \
    imagemagick \
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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN npm install -g n8n

WORKDIR /data

EXPOSE 80

USER node

ENV N8N_PORT=80

CMD ["n8n"]
