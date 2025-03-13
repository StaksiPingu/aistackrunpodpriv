#!/bin/bash

# System Update und Basisabhängigkeiten
apt-get update && apt-get upgrade -y
apt-get install -y wget git python3 python3-venv python3-pip \
    nvidia-cuda-toolkit python3-dev python3-setuptools python3-wheel \
    libsqlite3-dev build-essential curl nodejs npm

# Überprüfen, ob NVIDIA GPU verfügbar ist
if ! command -v nvidia-smi &> /dev/null; then
    echo "❌ Keine NVIDIA GPU erkannt! Skript wird abgebrochen."
    exit 1
fi

# CUDA 11.8 Installation für Stable Diffusion (falls nicht vorhanden)
CUDA_VERSION=$(nvcc --version | grep "release" | awk '{print $6}' | tr -d ",")
if [[ "$CUDA_VERSION" != "11.8" ]]; then
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
    dpkg -i cuda-keyring_1.0-1_all.deb
    apt-get update
    apt-get install -y cuda-toolkit-11-8
fi

# Ollama Installation
curl -fsSL https://ollama.com/install.sh | sh
nohup ollama serve &  # Startet Ollama im Hintergrund

# OpenWebUI Installation
git clone https://github.com/open-webui/open-webui.git
cd open-webui
npm install
nohup npm run start &  # Startet OpenWebUI im Hintergrund
cd ..

# Automatic1111 Stable Diffusion WebUI Installation
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui
python3 -m venv venv
source venv/bin/activate
pip3 install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip3 install --no-cache-dir -r requirements.txt
deactivate
nohup ./webui.sh --listen --port 7860 &  # Startet Stable Diffusion im Hintergrund
cd ..

# Environment Variablen setzen
echo 'export PATH=/usr/local/cuda-11.8/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-11.8/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc

echo "✅ Installation abgeschlossen!"
echo "🔗 OpenWebUI erreichbar unter: http://YOUR_RUNPOD_IP:3000"
echo "🎨 Stable Diffusion erreichbar unter: http://YOUR_RUNPOD_IP:7860"
echo "🖥 Ollama läuft im Hintergrund."
