#!/bin/bash
set -e

BASE_DIR="/workspace"
VENV_DIR="$BASE_DIR/venv"

echo "==== [1] Systemaktualisierung ===="
sudo apt update && sudo apt install -y python3.11 python3.11-venv

echo "==== [2] Virtuelle Umgebung erstellen ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [3] Open WebUI mit korrekten Abhängigkeiten installieren ===="
pip install "open-webui>=0.5.20" \
  "pydantic>=2.0" \
  "fastapi>=0.110.0" \
  "uvicorn>=0.29.0"

echo "==== [4] Ollama installieren ===="
curl -fsSL https://ollama.com/install.sh | sh
nohup ollama serve > "$BASE_DIR/ollama.log" 2>&1 &

echo "==== [5] Stable Diffusion installieren ===="
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$BASE_DIR/sd-webui"
cd "$BASE_DIR/sd-webui"
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt

nohup python launch.py --api --listen --port 7860 > "$BASE_DIR/sd-webui.log" 2>&1 &

echo "==== Erfolgreich installiert! ===="
echo "Open WebUI:   http://localhost:3000"
echo "Stable Diffusion: http://localhost:7860