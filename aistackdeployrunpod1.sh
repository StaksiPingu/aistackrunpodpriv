#!/bin/bash
set -e

# Konfiguration
BASE_DIR="/workspace"
OLLAMA_DIR="$BASE_DIR/ollama"
VENV_DIR="$BASE_DIR/venv"

echo "==== [1] System vorbereiten ===="
sudo apt update && sudo apt install -y \
  python3.11 python3.11-venv \
  git wget curl unzip \
  nvidia-driver-535 nvidia-utils-535  # NVIDIA-Treiber für GPU

echo "==== [2] Ollama installieren ===="
curl -fsSL https://ollama.com/install.sh | sh
sudo systemctl enable ollama
nohup ollama serve > $BASE_DIR/ollama.log 2>&1 &

echo "==== [3] Python-Umgebung erstellen ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [4] Open WebUI installieren ===="
pip install "open-webui>=0.5.20" "pydantic>=2.0"

echo "OLLAMA_BASE_URL=http://localhost:11434" > .env
nohup open-webui serve \
  --host 0.0.0.0 \
  --port 3000 > $BASE_DIR/webui.log 2>&1 &

echo "==== [5] Stable Diffusion installieren ===="
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git $BASE_DIR/sd-webui
cd $BASE_DIR/sd-webui

pip install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cu121  # CUDA 12.1

pip install -r requirements.txt

# Konfiguration für nicht-interaktiven Start
cat > webui-user.sh <<EOL
export COMMANDLINE_ARGS="--api --listen --port 7860 --skip-python-version-check"
EOL

nohup ./webui.sh > $BASE_DIR/sd-webui.log 2>&1 &

echo "==== Installation abgeschlossen ===="
echo "Open WebUI:   http://$(curl -s ifconfig.me):3000"
echo "Stable Diffusion: http://$(curl -s ifconfig.me):7860"
echo -e "\nLogs:"
ls -l $BASE_DIR/*.log