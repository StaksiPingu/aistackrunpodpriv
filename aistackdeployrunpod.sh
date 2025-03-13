#!/bin/bash

# System Update & Basisabhängigkeiten installieren
apt-get update && apt-get upgrade -y
apt-get install -y wget git python3 python3-venv python3-pip \
    python3-dev python3-setuptools python3-wheel \
    libsqlite3-dev build-essential curl nodejs npm docker.io

# Überprüfen, ob eine NVIDIA GPU verfügbar ist
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ Keine NVIDIA GPU erkannt! Skript wird abgebrochen."
    exit 1
fi

# Docker-Installation & Start
if ! command -v docker &> /dev/null; then
    echo "🚀 Docker wird installiert..."
    apt-get install -y docker.io
fi
echo "✅ Docker installiert. Starte Docker-Dienst..."
nohup dockerd > /dev/null 2>&1 &  # Startet Docker im Hintergrund

# CUDA 11.8 Installation für Stable Diffusion (falls nicht vorhanden)
if ! nvcc --version | grep -q "release 11.8"; then
    echo "🚀 CUDA 11.8 wird installiert..."
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    dpkg -i cuda-keyring_1.0-1_all.deb
    apt-get update
    apt-get install -y cuda-toolkit-11-8
fi

# Ollama Installation
echo "🚀 Installiere Ollama..."
curl -fsSL https://ollama.com/install.sh | sh
nohup ollama serve > /dev/null 2>&1 &  # Startet Ollama im Hintergrund

# OpenWebUI Installation mit Docker
echo "🚀 Klone OpenWebUI Repository..."
git clone https://github.com/open-webui/open-webui.git
cd open-webui
npm install
nohup docker-compose up --build -d > /dev/null 2>&1 &  # Startet OpenWebUI im Hintergrund mit Docker
cd ..

# Automatic1111 Stable Diffusion WebUI Installation
echo "🚀 Klone Stable Diffusion WebUI Repository..."
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui
python3 -m venv venv
source venv/bin/activate
pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install --no-cache-dir -r requirements.txt
deactivate
nohup ./webui.sh --listen --port 7860 > /dev/null 2>&1 &  # Startet Stable Diffusion im Hintergrund
cd ..

# Environment Variablen setzen
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

# Fertigmeldung
echo "✅ Installation abgeschlossen!"
echo "🔗 OpenWebUI erreichbar unter: http://YOUR_RUNPOD_IP:3000"
echo "🎨 Stable Diffusion erreichbar unter: http://YOUR_RUNPOD_IP:7860"
echo "🖥 Ollama läuft im Hintergrund."
echo "🐳 Docker läuft ebenfalls."

