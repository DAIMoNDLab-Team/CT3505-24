#!/bin/bash
# CT3505-24 macOS uninstaller.
# Removes EVERYTHING install-macos.command installs or creates: the
# "ct3505" conda environment, SUMO, XQuartz, Visual Studio Code, Miniconda,
# Rosetta 2, Homebrew itself, and this project's .env file.
#
# This is meant for wiping a machine back to a pristine state so the
# installer can be tested repeatedly and reliably. It is NOT a normal
# "remove this project" script: it deletes Homebrew, VS Code, and Miniconda
# entirely, including any extensions/environments/packages unrelated to
# this course. Do not run this on a machine you use those tools for.

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
ENV_NAME="ct3505"

step() { echo ""; echo "==> $1"; }

echo "CT3505-24 uninstaller"
echo "======================"
echo "This will COMPLETELY remove, including all user data/extensions/other"
echo "environments and packages:"
echo "  - the '$ENV_NAME' conda environment"
echo "  - SUMO and XQuartz"
echo "  - Visual Studio Code"
echo "  - Miniconda (and ALL conda environments, not just '$ENV_NAME')"
echo "  - Rosetta 2"
echo "  - Homebrew itself (and everything installed through it)"
echo "  - $PROJECT_DIR/.env"
echo ""
echo "This affects your whole Mac, not just this project folder."
read -p "Type 'yes' to continue: " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    read -p "Press Enter to close..."
    exit 1
fi

# Removes only the regular files/symlinks a pkg installed, then rmdir (which
# no-ops on non-empty dirs) any directories it also listed, deepest first.
# Deliberately never rm -rf a pkg-listed path: installer packages often list
# shared parent directories (e.g. /usr/local) among their "files", and
# force-deleting those would destroy unrelated software.
remove_pkg_files() {
    local pkg_id="$1"
    pkgutil --files "$pkg_id" 2>/dev/null | while IFS= read -r f; do
        local target="/$f"
        [[ -f "$target" || -L "$target" ]] && rm -f "$target"
    done
    pkgutil --files "$pkg_id" 2>/dev/null | sort -r | while IFS= read -r f; do
        local target="/$f"
        [[ -d "$target" ]] && rmdir "$target" 2>/dev/null
    done
    pkgutil --forget "$pkg_id" >/dev/null 2>&1
}

# --- 1. Conda environment ---
step "Removing the '$ENV_NAME' conda environment..."
CONDA_EXE=""
if command -v conda >/dev/null 2>&1; then
    CONDA_EXE="$(command -v conda)"
elif command -v brew >/dev/null 2>&1 && [[ -x "$(brew --prefix)/Caskroom/miniconda/base/bin/conda" ]]; then
    CONDA_EXE="$(brew --prefix)/Caskroom/miniconda/base/bin/conda"
fi
if [[ -n "$CONDA_EXE" ]]; then
    "$CONDA_EXE" env remove -y -n "$ENV_NAME" 2>/dev/null || echo "Environment '$ENV_NAME' not found, skipping."
else
    echo "conda not found, skipping."
fi

# --- 2. SUMO ---
step "Removing SUMO..."
for SUMO_PKG_ID in $(pkgutil --pkgs 2>/dev/null | grep -i sumo); do
    echo "Removing files installed by package $SUMO_PKG_ID..."
    remove_pkg_files "$SUMO_PKG_ID"
done
rm -rf /usr/local/share/sumo /usr/local/opt/sumo /Applications/sumo /Library/sumo 2>/dev/null
if command -v brew >/dev/null 2>&1; then
    brew uninstall --cask --zap sumo-gui >/dev/null 2>&1
    brew uninstall --zap sumo >/dev/null 2>&1
    brew untap dlr-ts/sumo >/dev/null 2>&1
fi

# --- 3. XQuartz ---
step "Removing XQuartz..."
if command -v brew >/dev/null 2>&1; then
    brew uninstall --cask --zap xquartz 2>/dev/null || echo "XQuartz not installed via Homebrew, skipping."
fi

# --- 4. Visual Studio Code ---
step "Removing Visual Studio Code..."
if command -v brew >/dev/null 2>&1; then
    brew uninstall --cask --zap visual-studio-code 2>/dev/null || echo "VS Code not installed via Homebrew, skipping."
fi
rm -rf "$HOME/Library/Application Support/Code" "$HOME/.vscode" "$HOME/.vscode-insiders" \
       "/Applications/Visual Studio Code.app" 2>/dev/null

# --- 5. Miniconda ---
step "Removing Miniconda..."
if command -v brew >/dev/null 2>&1; then
    brew uninstall --cask --zap miniconda 2>/dev/null || echo "Miniconda not installed via Homebrew, skipping."
fi
rm -rf "$HOME/miniconda3" "$HOME/opt/miniconda3" "$HOME/.condarc" "$HOME/.conda" 2>/dev/null
for RC in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
    if [[ -f "$RC" ]] && grep -q "# >>> conda initialize >>>" "$RC"; then
        sed -i '' '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$RC"
    fi
done

# --- 6. Rosetta 2 ---
step "Removing Rosetta 2..."
if [[ "$(uname -m)" == "arm64" ]]; then
    softwareupdate --uninstall-rosetta --agree-to-license 2>/dev/null || echo "Could not uninstall Rosetta 2 (it may be in use by other apps, or already removed)."
else
    echo "Not an Apple Silicon Mac, skipping."
fi

# --- 7. Homebrew ---
step "Removing Homebrew..."
if command -v brew >/dev/null 2>&1; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
else
    echo "Homebrew not found, skipping."
fi

# --- 8. Project .env file ---
step "Removing $PROJECT_DIR/.env..."
rm -f "$PROJECT_DIR/.env"

step "Done!"
echo "Your Mac should now be back to a clean state for re-testing install-macos.command."
echo "You may need to open a new Terminal window for PATH changes to take effect."
read -p $'\nPress Enter to close this window...'
