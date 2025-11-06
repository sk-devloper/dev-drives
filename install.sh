#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check for root privileges for installation
if [[ $EUID -ne 0 ]]; then
   echo "This installation script must be run with sudo." >&2
   exit 1
fi

echo "Starting dev-drives installation with pyenv..."

# --- 0. Check for pyenv ---
if ! command -v pyenv &> /dev/null; then
    echo "pyenv is not installed. Please install pyenv first (https://github.com/pyenv/pyenv#installation) and then re-run this script." >&2
    exit 1
fi

# Ensure pyenv is initialized for the current shell
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# --- 1. Install System Dependencies ---
echo "Installing system dependencies..."
apt update
apt install -y util-linux e2fsprogs

# --- 2. Setup Python Environment with pyenv ---
echo "Setting up Python environment with pyenv..."
PYTHON_VERSION="3.10.12" # Or another suitable version
VENV_NAME="dev-drives-venv"

# Install Python version if not already installed
if ! pyenv versions --bare | grep -q "$PYTHON_VERSION"; then
    echo "Installing Python $PYTHON_VERSION using pyenv..."
    pyenv install "$PYTHON_VERSION"
fi

# Create pyenv virtual environment if not already created
if ! pyenv virtualenvs --bare | grep -q "$VENV_NAME"; then
    echo "Creating pyenv virtual environment '$VENV_NAME' for Python $PYTHON_VERSION..."
    pyenv virtualenv "$PYTHON_VERSION" "$VENV_NAME"
fi

# Set the local pyenv version for the project directory
pyenv local "$VENV_NAME"

# Activate the virtual environment for the current script
pyenv activate "$VENV_NAME"

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

# Get the absolute path to the python executable within the pyenv virtual environment
# This path will be used directly in the wrapper script to avoid sudo/pyenv environment issues.
PYENV_VENV_PYTHON_EXEC="$(pyenv which python)"

cat <<EOF > "$WRAPPER_SCRIPT"
#!/bin/bash
# This wrapper script executes the dev-drives main.py script using its pyenv virtual environment.

# Ensure the script is run with sudo
if [[ $EUID -ne 0 ]]; then
   echo "The 'drive' command requires root privileges. Please run with sudo." >&2
   exit 1
fi

# Navigate to the project directory
cd "$PROJECT_DIR"

# Execute the main script using the python executable from the pyenv virtual environment
# This avoids issues with sudo and pyenv environment activation.
"$PYENV_VENV_PYTHON_EXEC" main.py "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"

echo "Installation complete. You can now use 'sudo drive <command>' from anywhere."
echo "Example: sudo drive create mydrive 512"
