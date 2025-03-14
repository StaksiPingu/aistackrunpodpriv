#!/bin/bash
set -e

BASE_DIR="/workspace"
OLLAMA_DIR="$BASE_DIR/ollama"
VENV_DIR="$BASE_DIR/venv"
SD_DIR="$BASE_DIR/stable-diffusion-webui"

echo "==== [1] Systemvorbereitung ===="
sudo apt update && sudo apt install -y \
  pciutils lshw git wget curl unzip nano \
  python3.11 python3.11-venv python3.11-dev

echo "==== [2] Ollama installieren ===="
mkdir -p "$OLLAMA_DIR"
curl -L https://ollama.com/download/ollama-linux-amd64 -o "$OLLAMA_DIR/ollama"
chmod +x "$OLLAMA_DIR/ollama"
export OLLAMA_MODELS="$OLLAMA_DIR/models"
nohup "$OLLAMA_DIR/ollama" serve > "$BASE_DIR/ollama.log" 2>&1 &

echo "==== [3] Python-Umgebung erstellen ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [4] Open WebUI installieren (mit pydantic 2.x) ===="
pip install "open-webui>=0.5.20" "pydantic>=2.0"

echo "OLLAMA_BASE_URL=http://localhost:11434" > "$BASE_DIR/.env"
nohup open-webui serve \
  --host 0.0.0.0 \
  --port 3000 \
  --env-file "$BASE_DIR/.env" > "$BASE_DIR/webui.log" 2>&1 &

echo "==== [5] Stable Diffusion installieren ===="
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$SD_DIR" || true
cd "$SD_DIR"
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
pip install -r requirements.txt

nohup python launch.py \
  --api \
  --listen \
  --port 7860 \
  --no-download-sd-model > "$BASE_DIR/sd-webui.log" 2>&1 &

echo "==== Erfolgreich! ===="
echo "Open WebUI:   http://localhost:3000"
echo "Stable Diffusion: http://localhost:7860"