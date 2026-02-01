#!/bin/bash
# Start all SIC Framework components using tmux
# Usage: ./start_all_tmux.sh
#
# After running, use these tmux commands:
#   Ctrl+b then number (0-5) - switch between panes
#   Ctrl+b then d            - detach from session
#   tmux attach -t sic       - reattach to session
#   Ctrl+b then :kill-session - kill all

SESSION="sic"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONDA_ENV="PCA26"

# Detect OS
OS="$(uname -s)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "ERROR: tmux is not installed."
    if [[ "$OS" == "Darwin" ]]; then
        echo "Install it with: brew install tmux"
    else
        echo "Install it with: sudo apt install tmux (ubuntu/debian), sudo dnf install tmux (fedora), etc."
    fi
    exit 1
fi

# Detect conda installation path
if [[ -f ~/anaconda3/etc/profile.d/conda.sh ]]; then
    CONDA_INIT="source ~/anaconda3/etc/profile.d/conda.sh && conda activate $CONDA_ENV"
elif [[ -f ~/miniconda3/etc/profile.d/conda.sh ]]; then
    CONDA_INIT="source ~/miniconda3/etc/profile.d/conda.sh && conda activate $CONDA_ENV"
elif [[ -f /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh ]]; then
    # Common Homebrew miniconda location on Apple Silicon
    CONDA_INIT="source /opt/homebrew/Caskroom/miniconda/base/etc/profile.d/conda.sh && conda activate $CONDA_ENV"
elif [[ -f /usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh ]]; then
    # Common Homebrew miniconda location on Intel Mac
    CONDA_INIT="source /usr/local/Caskroom/miniconda/base/etc/profile.d/conda.sh && conda activate $CONDA_ENV"
elif command -v conda &> /dev/null; then
    # Fallback: conda is in PATH, use conda's own init
    CONDA_INIT="eval \"\$(conda shell.bash hook)\" && conda activate $CONDA_ENV"
else
    echo "ERROR: Could not find conda installation."
    echo "Please install Anaconda or Miniconda first."
    exit 1
fi

# Kill existing session if it exists
tmux kill-session -t $SESSION 2>/dev/null

echo -e "${GREEN}Creating tmux session '$SESSION' with all components...${NC}"

# Create new session with first window (Redis)
tmux new-session -d -s $SESSION -n "Redis"
tmux send-keys -t $SESSION:Redis "$CONDA_INIT && cd '$SCRIPT_DIR/sic_applications' && redis-server conf/redis/redis.conf" C-m

# Wait for Redis to start
sleep 2

# Create window for Google STT
tmux new-window -t $SESSION -n "GoogleSTT"
tmux send-keys -t $SESSION:GoogleSTT "$CONDA_INIT && cd '$SCRIPT_DIR' && run-google-stt" C-m

# Create window for NLU
tmux new-window -t $SESSION -n "NLU"
tmux send-keys -t $SESSION:NLU "$CONDA_INIT && cd '$SCRIPT_DIR' && run-nlu" C-m

# Create window for Webserver
tmux new-window -t $SESSION -n "Webserver"
tmux send-keys -t $SESSION:Webserver "$CONDA_INIT && cd '$SCRIPT_DIR' && run-webserver" C-m

# Wait for services to be ready
sleep 3

# Create window for Framework
tmux new-window -t $SESSION -n "Framework"
tmux send-keys -t $SESSION:Framework "$CONDA_INIT && cd '$SCRIPT_DIR' && start-framework" C-m

# Wait for framework to start
sleep 3

# Create window for EIS
tmux new-window -t $SESSION -n "EIS"
tmux send-keys -t $SESSION:EIS "$CONDA_INIT && cd '$SCRIPT_DIR' && run-eis --use-nlu" C-m

# Select the first window
tmux select-window -t $SESSION:Redis

echo -e "${GREEN}All components started in tmux session '$SESSION'${NC}"
echo ""
echo -e "${YELLOW}Tmux commands:${NC}"
echo "  tmux attach -t $SESSION    - Attach to the session"
echo "  Ctrl+b then 0-5            - Switch between windows"
echo "  Ctrl+b then n/p            - Next/Previous window"
echo "  Ctrl+b then d              - Detach from session"
echo "  Ctrl+b then :kill-session  - Kill all windows"
echo ""
echo -e "${GREEN}Attaching to session now...${NC}"

# Attach to the session
tmux attach -t $SESSION
