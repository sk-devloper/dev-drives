#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check for root privileges for installation
if [[ $EUID -ne 0 ]]; then
   echo "This installation script must be run with sudo." >&2
   exit 1
fi

echo "Starting dev-drives installation..."

# --- 1. Install System Dependencies ---
echo "Installing system dependencies..."
apt update
apt install -y util-linux e2fsprogs

# --- 2. Setup Python Environment ---
echo "Setting up Python environment..."
PYTHON_BIN=$(which python3)
if [ -z "$PYTHON_BIN" ]; then
    echo "Python 3 is not installed. Please install Python 3 and try again." >&2
    exit 1
fi

# Create a virtual environment in the project directory
VENV_DIR="$(pwd)/.venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment at $VENV_DIR"
    $PYTHON_BIN -m venv "$VENV_DIR"
fi

# Activate the virtual environment for the current script
source "$VENV_DIR/bin/activate"

# Install Python dependencies (if any)
if [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies from requirements.txt"
    pip install -r requirements.txt
fi

# --- 3. Create 'drive' command ---
echo "Creating 'drive' command..."

# Create a wrapper script in /usr/local/bin
WRAPPER_SCRIPT="/usr/local/bin/drive"
PROJECT_DIR="$(pwd)" # Get the current project directory

cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
# This wrapper script executes the dev-drives main.py script.

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "The 'drive' command requires root privileges. Please run with sudo." >&2
   exit 1
fi

# Navigate to the project directory
cd "$PROJECT_DIR"

# Activate the virtual environment
source "$VENV_DIR/bin/activate"

# Execute the main script with sudo (already checked above)
python3 main.py "$@"

# Deactivate the virtual environment (optional, as script exits)
deactivate
EOF

chmod +x "$WRAPPER_SCRIPT"

echo "Installation complete. You can now use 'sudo drive <command>' from anywhere."
echo "Example: sudo drive create mydrive 512"