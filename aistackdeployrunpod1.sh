#!/bin/bash
set -e

# Konfiguration
BASE_DIR="/workspace"
OLLAMA_DIR="$BASE_DIR/ollama"
VENV_DIR="$BASE_DIR/venv"
SD_DIR="$BASE_DIR/stable-diffusion-webui"

echo "==== [1] Systemaktualisierung ===="
sudo apt update && sudo apt install -y \
  python3.11 python3.11-venv \
  git wget curl unzip \
  nvidia-driver-535 nvidia-utils-535

echo "==== [2] Ollama installieren ===="
rm -rf "$OLLAMA_DIR"
mkdir -p "$OLLAMA_DIR"
curl -L https://ollama.com/download/ollama-linux-amd64 -o "$OLLAMA_DIR/ollama"
chmod +x "$OLLAMA_DIR/ollama"

# Ollama mit korrektem Model-Pfad starten
export OLLAMA_MODELS="$OLLAMA_DIR/models"
nohup env OLLAMA_MODELS=$OLLAMA_MODELS "$OLLAMA_DIR/ollama" serve > "$BASE_DIR/ollama.log" 2>&1 &
sleep 5

echo "==== [3] Python-Umgebung erstellen ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [4] Open WebUI installieren ===="
pip install "open-webui>=0.5.20" "pydantic>=2.0"

# Open WebUI starten
OLLAMA_BASE_URL=http://localhost:11434 nohup open-webui serve \
  --host 0.0.0.0 \
  --port 3000 > "$BASE_DIR/webui.log" 2>&1 &

echo "==== [5] Stable Diffusion installieren ===="
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$SD_DIR"
cd "$SD_DIR"
pip install xformers==0.0.24

nohup python launch.py \
  --api \
  --listen \
  --port 7860 \
  --xformers \
  --skip-torch-cuda-test \
  --no-download-sd-model > "$BASE_DIR/sd-webui.log" 2>&1 &

echo "==== [6] Testmodell herunterladen ===="
# Modelldownload mit korrekten Umgebungsvariablen
cd "$OLLAMA_DIR"
env OLLAMA_MODELS=$OLLAMA_MODELS ./ollama pull llama2 2>&1 | tee -a "$BASE_DIR/ollama.log"

echo "==== Installation abgeschlossen ===="
echo -e "\nZugangslinks:"
echo "Open WebUI:   http://localhost:3000"
echo "Stable Diffusion: http://localhost:7860"