#!/bin/bash
set -e

BASE_DIR="/workspace"
OLLAMA_DIR="$BASE_DIR/ollama"
VENV_DIR="$BASE_DIR/venv"
SD_DIR="$BASE_DIR/stable-diffusion-webui"

echo "==== [1] Systembereinigung ===="
sudo apt purge -y "*cuda*" "*nvidia*"
sudo apt autoremove -y

echo "==== [2] Ollama Neuinstallation ===="
rm -rf "$OLLAMA_DIR"
mkdir -p "$OLLAMA_DIR"
curl -L https://ollama.com/download/ollama-linux-amd64 -o "$OLLAMA_DIR/ollama"
chmod +x "$OLLAMA_DIR/ollama"
export OLLAMA_MODELS="$OLLAMA_DIR/models"

# Test der Ollama-Installation
if ! "$OLLAMA_DIR/ollama" --version; then
  echo "❌ Ollama-Installation fehlgeschlagen"
  exit 1
fi

echo "==== [3] Python-Umgebung ===="
python3.11 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"
pip install --upgrade pip

echo "==== [4] Open WebUI ===="
pip install "open-webui>=0.5.20" "pydantic>=2.0"

echo "==== [5] Stable Diffusion ===="
git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$SD_DIR"
cd "$SD_DIR"

# CUDA 12.1 Kompatibilität
pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 \
  --index-url https://download.pytorch.org/whl/cu121

# XFormers Installation
pip install xformers==0.0.24 --no-deps

# Startskript
cat > webui-user.sh <<EOL
#!/bin/bash
export COMMANDLINE_ARGS="--api --listen --xformers --skip-torch-cuda-test"
EOL

chmod +x webui-user.sh
nohup ./webui.sh > "$BASE_DIR/sd-webui.log" 2>&1 &

echo "==== [6] Finaler Test ===="
cd "$OLLAMA_DIR"
timeout 60 ./ollama pull llama2 2>&1 | tee -a "$BASE_DIR/ollama.log"

echo "==== ✅ Installation erfolgreich ===="
echo "Open WebUI:   http://localhost:3000"
echo "Stable Diffusion: http://localhost:7860"