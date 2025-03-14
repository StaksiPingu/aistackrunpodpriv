#!/bin/bash

# Setze Fehlermodus (Skript stoppt bei Fehlern)
set -e

echo "==== [1] System aktualisieren & Hardware-Tools installieren ===="
apt update && apt install -y pciutils lshw git wget curl unzip

echo "==== [2] Installiere Ollama ===="
curl -fsSL https://ollama.com/install.sh | sh

echo "==== [3] Starte Ollama im Hintergrund ===="
nohup ollama serve > ollama.log 2>&1 &

echo "==== [4] Installiere Python 3.11 & Virtual Environment ===="
apt update && apt install -y python3.11 python3.11-venv python3.11-dev

echo "==== [5] Erstelle & aktiviere Python 3.11 Virtual Environment ===="
python3.11 -m venv venv
source venv/bin/activate

echo "==== [6] Upgrade pip & installiere Open WebUI ===="
pip install --upgrade pip
pip install open-webui

echo "==== [7] Starte Open WebUI im Hintergrund ===="
mkdir -p /workspace/logs
source venv/bin/activate
nohup python3 -m open_webui serve --host 0.0.0.0 --port 3000 > /workspace/logs/webui.log 2>&1 &

echo "==== [8] Installiere AUTOMATIC1111 (Stable Diffusion WebUI) ===="
cd /workspace
if [ ! -d "stable-diffusion-webui" ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
fi
cd stable-diffusion-webui

# Installiere die benötigten Abhängigkeiten (CUDA 11.8 Kompatibilität sicherstellen)
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt

echo "==== [9] Starte AUTOMATIC1111 im Hintergrund ===="
mkdir -p /workspace/logs
nohup python3 launch.py --listen --port 7860 > /workspace/logs/sd-webui.log 2>&1 &

echo "==== [10] Setup abgeschlossen! ===="
echo "Open WebUI läuft auf Port 3000"
echo "AUTOMATIC1111 (Stable Diffusion WebUI) läuft auf Port 7860"

exec bash  # Hält die Session offen