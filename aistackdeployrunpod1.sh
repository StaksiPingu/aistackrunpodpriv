#!/bin/bash
set -e

BASE_DIR="/workspace"
OLLAMA_DIR="$BASE_DIR/ollama"
VENV_DIR="$BASE_DIR/venv"
SD_DIR="$BASE_DIR/stable-diffusion-webui"

echo "==== [1] Ollama Installation ===="
rm -rf "$OLLAMA_DIR"
mkdir -p "$OLLAMA_DIR"
curl -L https://ollama.com/download/ollama-linux-amd64 -o "$OLLAMA_DIR/ollama"
chmod +x "$OLLAMA_DIR/ollama"
export OLLAMA_MODELS="$OLLAMA_DIR/models"

# Ollama Service starten
nohup "$OLLAMA_DIR/ollama" serve > "$BASE_DIR/ollama.log" 2>&1 &
sleep 5

echo "==== [2] Python-Umgebung ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [3] Open WebUI ===="
pip install "open-webui>=0.5.20" "pydantic>=2.0"

# Port 3000 freigeben
pkill -f "3000" || true
nohup open-webui serve --host 0.0.0.0 --port 3000 > "$BASE_DIR/webui.log 2>&1 &

echo "==== [4] Stable Diffusion ===="
[ ! -d "$SD_DIR" ] && git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$SD_DIR"
cd "$SD_DIR"

pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 \
  --index-url https://download.pytorch.org/whl/cu121

pip install xformers==0.0.24 --no-deps

# Port 7860 freigeben
pkill -f "7860" || true
nohup python launch.py --api --listen --xformers > "$BASE_DIR/sd-webui.log 2>&1 &

echo "==== [5] Modell-Download ===="
timeout 60 "$OLLAMA_DIR/ollama" pull llama2 2>&1 | tee -a "$BASE_DIR/ollama.log"

echo "==== ✅ Fertig ===="
echo -e "\nZugangslinks:"
echo "Open WebUI:   http://localhost:3000"
echo "Stable Diffusion: http://localhost:7860"
echo -e "\nLogs:"
ls "$BASE_DIR"/*.log