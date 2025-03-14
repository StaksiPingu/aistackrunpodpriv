#!/bin/bash
set -e

echo "==== [1] System aktualisieren & Hardware-Tools installieren ===="
apt update && apt install -y pciutils lshw git wget curl unzip nano

echo "==== [2] Installiere Ollama ===="
cd /workspace
curl -fsSL https://ollama.com/install.sh | sh

echo "==== [3] Starte Ollama im Hintergrund ===="
nohup ollama serve > /workspace/ollama.log 2>&1 &

echo "==== [4] Installiere Python 3.11 & Virtual Environment ===="
apt update && apt install -y python3.11 python3.11-venv python3.11-dev

echo "==== [5] Erstelle & aktiviere Python 3.11 Virtual Environment ===="
if [ ! -d "/workspace/venv" ]; then
    python3.11 -m venv /workspace/venv
fi
source /workspace/venv/bin/activate

echo "==== [6] Upgrade pip & installiere Open WebUI ===="
pip install --upgrade pip
pip uninstall -y pydantic  # Entferne falsche Version
pip install "pydantic<2.0" # Installiere kompatible Version
pip install open-webui

echo "==== [7] Starte Open WebUI im Hintergrund ===="
nohup open-webui serve --host 0.0.0.0 --port 3000 > /workspace/webui.log 2>&1 &
sleep 5
if ! pgrep -f "open-webui" > /dev/null; then
    echo "❌ Open WebUI konnte nicht gestartet werden!"
    cat /workspace/webui.log
    exit 1
fi

echo "==== [8] Installiere AUTOMATIC1111 (Stable Diffusion WebUI) ===="
cd /workspace
if [ ! -d "stable-diffusion-webui" ]; then
    git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git
fi
cd stable-diffusion-webui
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt

echo "==== [9] Starte AUTOMATIC1111 im Hintergrund ===="
nohup python launch.py --api --listen --port 7860 > /workspace/sd-webui.log 2>&1 &
sleep 5
if ! pgrep -f "launch.py" > /dev/null; then
    echo "❌ Stable Diffusion WebUI konnte nicht gestartet werden!"
    cat /workspace/sd-webui.log
    exit 1
fi

echo "==== [10] Setup abgeschlossen! ===="
echo "✅ Open WebUI läuft auf Port 3000"
echo "✅ AUTOMATIC1111 (Stable Diffusion WebUI) läuft auf Port 7860"