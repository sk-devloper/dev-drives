#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting installation of dev-drives CLI tool..."

# Check for python3
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found. Please install python3 to continue."
    exit 1
fi

# Ensure python3-venv is installed for virtual environment creation
if ! dpkg -s python3-venv &> /dev/null; then
    echo "python3-venv package not found. Installing..."
    apt update
    apt install -y python3-venv
fi

# Check for pip
if ! command -v pip &> /dev/null
then
    echo "pip could not be found. Attempting to install pip..."
    python3 -m ensurepip --default-pip
    if ! command -v pip &> /dev/null
    then
        echo "pip installation failed. Please install pip manually."
        exit 1
    fi
fi

# Create and activate a virtual environment
if [ -d ".venv" ]; then
    echo "Removing existing virtual environment..."
    rm -rf .venv
fi

echo "Creating a Python virtual environment..."
python3 -m venv .venv || { echo "Failed to create virtual environment."; exit 1; }

echo "Checking contents of .venv/bin..."
ls -la .venv/bin

echo "Activating virtual environment..."
source .venv/bin/activate || { echo "Failed to activate virtual environment."; exit 1; }

echo "Installing Python dependencies from requirements.txt into the virtual environment..."
pip install -r requirements.txt

# Deactivate the virtual environment after installation
deactivate

echo "Making main.py executable..."
chmod +x main.py

# Determine installation path for the wrapper script
INSTALL_PATH="/usr/local/bin"
if [[ ! -w "$INSTALL_PATH" ]]; then
    echo "Warning: /usr/local/bin is not writable. Attempting to install to ~/.local/bin."
    INSTALL_PATH="$HOME/.local/bin"
    mkdir -p "$INSTALL_PATH"
    if [[ ! -w "$INSTALL_PATH" ]]; then
        echo "Error: Neither /usr/local/bin nor ~/.local/bin are writable. Please run with sudo or adjust permissions."
        exit 1
    fi
fi

# Create a wrapper script to run the main.py using the virtual environment
WRAPPER_NAME="dev-drives"
WRAPPER_SCRIPT_PATH="$INSTALL_PATH/$WRAPPER_NAME"
PROJECT_ROOT="$(pwd)"

cat <<EOF > "$WRAPPER_SCRIPT_PATH"
#!/bin/bash
# This wrapper script executes the dev-drives main.py script using its virtual environment.

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "The '$WRAPPER_NAME' command requires root privileges. Please run with sudo." >&2
   exit 1
fi

# Navigate to the project directory
cd "$PROJECT_ROOT"

# Activate the virtual environment and run the main script
source .venv/bin/activate
./main.py "$@"
deactivate # Deactivate after execution
EOF

chmod +x "$WRAPPER_SCRIPT_PATH"

echo "Installation complete. You can now run 'sudo $WRAPPER_NAME <command>' from anywhere in your terminal."
echo "If '$WRAPPER_NAME' command is not found, ensure $INSTALL_PATH is in your PATH environment variable."