#!/bin/bash
# CT3505-24 macOS installer.
# Double-click this file in Finder to install everything needed for
# Assignments 1 & 2: Homebrew, Miniconda, SUMO, VS Code, and the
# "ct3505" conda environment with its Python packages. Safe to re-run.

set -e
cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
ENV_NAME="ct3505"

step() { echo ""; echo "==> $1"; }

echo "CT3505-24 installer"
echo "===================="

# --- 1. Homebrew ---
step "Checking for Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
    echo "Installing Homebrew (you may be asked for your Mac login password)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -d /opt/homebrew/bin ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -d /usr/local/bin ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
fi
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew installation did not complete. Please open a new Terminal window and re-run this installer."
    read -p "Press Enter to close..."
    exit 1
fi
BREW_PREFIX="$(brew --prefix)"
echo "Using Homebrew: $BREW_PREFIX"

# --- 2. Miniconda ---
step "Checking for conda..."
CONDA_EXE=""
if command -v conda >/dev/null 2>&1; then
    CONDA_EXE="$(command -v conda)"
elif [[ -x "$BREW_PREFIX/Caskroom/miniconda/base/bin/conda" ]]; then
    CONDA_EXE="$BREW_PREFIX/Caskroom/miniconda/base/bin/conda"
fi

if [[ -z "$CONDA_EXE" ]]; then
    echo "Installing Miniconda..."
    brew install --cask miniconda
    if [[ -x "$BREW_PREFIX/Caskroom/miniconda/base/bin/conda" ]]; then
        CONDA_EXE="$BREW_PREFIX/Caskroom/miniconda/base/bin/conda"
    fi
fi

if [[ -z "$CONDA_EXE" || ! -x "$CONDA_EXE" ]]; then
    echo "Could not locate conda after installation. Please open a new Terminal window and re-run this installer."
    read -p "Press Enter to close..."
    exit 1
fi
echo "Using conda: $CONDA_EXE"

# --- 3. Rosetta 2 (Apple Silicon only) ---
step "Checking for Rosetta 2..."
if [[ "$(uname -m)" == "arm64" ]]; then
    if arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
        echo "Rosetta 2 is already installed."
    else
        echo "Installing Rosetta 2 (required to run SUMO on Apple Silicon)..."
        softwareupdate --install-rosetta --agree-to-license
    fi
else
    echo "Not an Apple Silicon Mac, skipping."
fi

# --- 4. SUMO ---
step "Checking for SUMO..."

# Looks for an existing SUMO install (however it got there) by checking common
# install locations for a "tools" subfolder, which only a real SUMO_HOME has.
# The official .pkg installer ships SUMO as a macOS framework bundle, so that
# takes priority (see tools/build_config/buildMacOSInstaller.py upstream).
find_sumo_home() {
    local candidate
    for candidate in "/Library/Frameworks/EclipseSUMO.framework/Versions/Current/EclipseSUMO/share/sumo" \
                      /usr/local/share/sumo /usr/local/opt/sumo/share/sumo \
                      /opt/homebrew/share/sumo /opt/homebrew/opt/sumo/share/sumo \
                      /Applications/sumo /Library/sumo; do
        if [[ -d "$candidate/tools" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    find -L /usr/local /opt /Applications /Library -maxdepth 8 -type d -name sumo -path "*share*" 2>/dev/null | head -n1
}

SUMO_HOME_PATH="${SUMO_HOME:-}"
if [[ -z "$SUMO_HOME_PATH" ]]; then
    SUMO_HOME_PATH="$(find_sumo_home)"
fi

if [[ -z "$SUMO_HOME_PATH" ]] && ! command -v sumo >/dev/null 2>&1; then
    # The dlr-ts/sumo Homebrew formula is outdated and crashes on install,
    # so we use SUMO's official .pkg installer from sumo.dlr.de instead.
    echo "Installing SUMO from the official installer package..."
    SUMO_VERSION="1.27.1"
    SUMO_PKG_URL="https://sumo.dlr.de/releases/${SUMO_VERSION}/sumo-${SUMO_VERSION}.pkg"
    # installer(8) requires a ".pkg" extension to recognize the file, so put
    # it in its own temp dir with a fixed name rather than relying on mktemp's
    # random suffix.
    SUMO_TMP_DIR="$(mktemp -d -t sumo-pkg)"
    SUMO_PKG_FILE="$SUMO_TMP_DIR/sumo.pkg"
    echo "Downloading $SUMO_PKG_URL ..."
    if ! curl -fsSL "$SUMO_PKG_URL" -o "$SUMO_PKG_FILE"; then
        echo "That version is no longer available, falling back to the nightly build..."
        SUMO_PKG_URL="https://sumo.dlr.de/daily/sumo-git.pkg"
        curl -fsSL "$SUMO_PKG_URL" -o "$SUMO_PKG_FILE"
    fi
    echo "Installing SUMO (you may be asked for your Mac login password)..."
    sudo installer -pkg "$SUMO_PKG_FILE" -target /
    rm -rf "$SUMO_TMP_DIR"

    # sumo-gui and netedit need XQuartz to run.
    if [[ ! -d "/Applications/Utilities/XQuartz.app" && ! -d "/opt/X11" ]]; then
        echo "Installing XQuartz (required for sumo-gui and netedit)..."
        brew install --cask xquartz
    fi

    SUMO_HOME_PATH="$(find_sumo_home)"
fi

if [[ -n "$SUMO_HOME_PATH" ]]; then
    echo "Using SUMO_HOME: $SUMO_HOME_PATH"
else
    echo "Could not automatically locate the SUMO install folder. You may need to set SUMO_HOME manually (see FAQs.md)."
fi

# --- 5. Add SUMO to PATH ---
step "Adding SUMO's bin folder to your PATH..."
if [[ -n "$SUMO_HOME_PATH" && "$SUMO_HOME_PATH" == */share/sumo ]]; then
    SUMO_BIN_PATH="${SUMO_HOME_PATH%/share/sumo}/bin"
    if [[ -d "$SUMO_BIN_PATH" ]]; then
        export PATH="$SUMO_BIN_PATH:$PATH"
        for RC in "$HOME/.zshrc" "$HOME/.bash_profile"; do
            [[ -f "$RC" ]] || touch "$RC"
            if ! grep -q "# >>> ct3505 sumo path >>>" "$RC" 2>/dev/null; then
                {
                    echo ""
                    echo "# >>> ct3505 sumo path >>>"
                    echo "export PATH=\"$SUMO_BIN_PATH:\$PATH\""
                    echo "# <<< ct3505 sumo path <<<"
                } >> "$RC"
            fi
        done
        echo "Added $SUMO_BIN_PATH to PATH in ~/.zshrc and ~/.bash_profile (open a new terminal to pick it up)."
    else
        echo "Expected SUMO's bin folder at $SUMO_BIN_PATH but it doesn't exist, skipping."
    fi
else
    echo "SUMO_HOME not set, skipping."
fi

# --- 6. VS Code ---
step "Checking for Visual Studio Code..."
if ! command -v code >/dev/null 2>&1 && [[ ! -d "/Applications/Visual Studio Code.app" ]]; then
    echo "Installing Visual Studio Code..."
    brew install --cask visual-studio-code
else
    echo "Visual Studio Code is already installed."
fi

# --- 7. Accept conda Terms of Service ---
step "Accepting conda's Terms of Service for the main and r channels..."
"$CONDA_EXE" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main \
    || echo "Note: could not run 'conda tos accept' for the main channel (fine on older conda versions that don't require it)."
"$CONDA_EXE" tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r \
    || echo "Note: could not run 'conda tos accept' for the r channel (fine on older conda versions that don't require it)."

# --- 8. Conda environment ---
step "Setting up the '$ENV_NAME' conda environment..."
if "$CONDA_EXE" env list | grep -qE "^${ENV_NAME}[[:space:]]"; then
    echo "Environment '$ENV_NAME' already exists."
else
    "$CONDA_EXE" create -y -n "$ENV_NAME" python=3.11 pip
fi

# --- 9. Python packages ---
# Pinned to mercury 3.2.4 and tud-sumo 3.3.2: the exact versions the
# notebooks' code was migrated/verified against, so a future release of
# either package doesn't silently break the assignment again (tud-sumo
# 3.3.1 renamed Simulation.start()'s get_individual_vehicle_data kwarg to
# get_fc_data, which broke Assignment 1 the same way mercury 3.x did).
step "Installing lxml, tud-sumo, mercury, pandas, and python-dotenv..."
"$CONDA_EXE" run -n "$ENV_NAME" pip install --upgrade pip
"$CONDA_EXE" run -n "$ENV_NAME" pip install lxml "tud-sumo==3.3.2" "mercury==3.2.4" pandas python-dotenv

# --- 10. .env file ---
step "Writing SUMO_HOME to .env..."
ENV_FILE="$PROJECT_DIR/.env"
if [[ -n "$SUMO_HOME_PATH" ]]; then
    if [[ -f "$ENV_FILE" ]]; then
        grep -v "^SUMO_HOME=" "$ENV_FILE" > "$ENV_FILE.tmp" 2>/dev/null || true
        mv "$ENV_FILE.tmp" "$ENV_FILE"
    fi
    echo "SUMO_HOME=$SUMO_HOME_PATH" >> "$ENV_FILE"
fi

step "Done!"
echo "Open VS Code, then File -> Open Folder... and select:"
echo "  $PROJECT_DIR"
echo "Open Assignment_1.ipynb or Assignment_2.ipynb, click 'Select Kernel...' -> 'Python Environments...' and choose '$ENV_NAME'."
echo "For Assignment 1, run 'mercury --working-dir .' in the VS Code terminal (with the '$ENV_NAME' environment active), or double-click run-assignment1-macos.command."
read -p $'\nPress Enter to close this window...'
