#!/bin/bash
set -e

# Konfiguration
BASE_DIR="/workspace"
OLLAMA_DIR="$BASE_DIR/ollama"
VENV_DIR="$BASE_DIR/venv"
SD_DIR="$BASE_DIR/stable-diffusion-webui"

echo "==== [1] System vorbereiten ===="
sudo apt update && sudo apt install -y \
  python3.11 python3.11-venv \
  git wget curl unzip \
  nvidia-driver-535 nvidia-utils-535  # NVIDIA-Treiber

echo "==== [2] Ollama installieren ===="
mkdir -p "$OLLAMA_DIR"
curl -L https://ollama.com/download/ollama-linux-amd64 -o "$OLLAMA_DIR/ollama"
chmod +x "$OLLAMA_DIR/ollama"
export OLLAMA_MODELS="$OLLAMA_DIR/models"

# Ollama als Hintergrundprozess starten
nohup "$OLLAMA_DIR/ollama" serve > "$BASE_DIR/ollama.log" 2>&1 &

echo "==== [3] Python-Umgebung erstellen ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [4] Open WebUI installieren ===="
pip install "open-webui>=0.5.20" "pydantic>=2.0"

# Open WebUI konfigurieren
echo "OLLAMA_BASE_URL=http://localhost:11434" > "$BASE_DIR/.env"
nohup open-webui serve \
  --host 0.0.0.0 \
  --port 3000 \
  --env-file "$BASE_DIR/.env" > "$BASE_DIR/webui.log" 2>&1 &

echo "==== [5] Stable Diffusion installieren ===="
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$SD_DIR"
cd "$SD_DIR"

# PyTorch mit CUDA 12.1 installieren
pip install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cu121

# Stable Diffusion starten
nohup python launch.py \
  --api \
  --listen \
  --port 7860 \
  --skip-torch-cuda-test \
  --no-download-sd-model > "$BASE_DIR/sd-webui.log" 2>&1 &

echo "==== Installation erfolgreich! ===="
echo -e "\nServices:"
echo "Ollama:      Port 11434 (Log: $BASE_DIR/ollama.log)"
echo "Open WebUI:  http://localhost:3000 (Log: $BASE_DIR/webui.log)"
echo "StableDiff:  http://localhost:7860 (Log: $BASE_DIR/sd-webui.log)"