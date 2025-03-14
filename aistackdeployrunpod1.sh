#!/bin/bash

# Setze Fehlermodus (Skript stoppt bei Fehlern)
set -e

echo "==== [1] System aktualisieren & Hardware-Tools installieren ===="
apt update && apt install -y pciutils lshw git wget curl unzip

echo "==== [2] Wechsle zu persistenter Speicherplatz unter /workspace ===="
cd /workspace

echo "==== [3] Installiere Ollama ===="
curl -fsSL https://ollama.com/install.sh | sh

echo "==== [4] Starte Ollama im Hintergrund mit persistenter Speicherung ===="
mkdir -p /workspace/ollama
OLLAMA_MODEL_DIR="/workspace/ollama" nohup ollama serve > /workspace/logs/ollama.log 2>&1 &

echo "==== [5] Installiere Python 3.11 & Virtual Environment ===="
apt update && apt install -y python3.11 python3.11-venv python3.11-dev

echo "==== [6] Erstelle & aktiviere Python 3.11 Virtual Environment ===="
python3.11 -m venv /workspace/venv
source /workspace/venv/bin/activate

echo "==== [7] Upgrade pip & installiere Open WebUI ===="
pip install --upgrade pip
pip install open-webui

echo "==== [8] Starte Open WebUI mit persistenter Speicherung ===="
mkdir -p /workspace/open-webui
nohup open-webui serve --host 0.0.0.0 --port 3000 > /workspace/logs/webui.log 2>&1 &

echo "==== [9] Installiere AUTOMATIC1111 (Stable Diffusion WebUI) ===="
mkdir -p /workspace/stable-diffusion
cd /workspace/stable-diffusion
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
cd stable-diffusion-webui

# Installiere CUDA-kompatible PyTorch-Version
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt

echo "==== [10] Starte AUTOMATIC1111 mit persistenter Speicherung ===="
mkdir -p /workspace/models
nohup python launch.py --listen --port 7860 --ckpt-dir /workspace/models > /workspace/logs/sd-webui.log 2>&1 &

echo "==== [11] Setup abgeschlossen! ===="
echo "Open WebUI läuft auf Port 3000"
echo "Stable Diffusion (AUTOMATIC1111) läuft auf Port 7860"
echo "Ollama läuft im Hintergrund"
exec bash  # Hält die Session offen