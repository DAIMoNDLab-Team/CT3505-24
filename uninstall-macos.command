#!/bin/bash
# CT3505-24 macOS uninstaller.
# Removes the "ct3505" conda environment and this project's .env file, plus
# ONLY the system-wide tools (Homebrew, Miniconda, SUMO, XQuartz, VS Code,
# Rosetta 2) that install-macos.command itself installed - never software
# you already had on your Mac before running it.
#
# This relies on the install manifest install-macos.command writes
# (.ct3505-install-manifest, in this project folder) to know what it
# actually installed vs. what it found already present. If that manifest
# is missing (e.g. an older install-macos.command was used, or the file was
# deleted), this script assumes it installed no system-wide tools and
# leaves Homebrew/Miniconda/SUMO/XQuartz/VS Code/Rosetta alone entirely -
# it will still remove the "ct3505" conda environment and this project's
# .env file, since those are unambiguously project-specific either way.

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"
ENV_NAME="ct3505"
MANIFEST_FILE="$PROJECT_DIR/.ct3505-install-manifest"

step() { echo ""; echo "==> $1"; }

INSTALLED_HOMEBREW=false
INSTALLED_MINICONDA=false
INSTALLED_ROSETTA=false
INSTALLED_SUMO=false
INSTALLED_XQUARTZ=false
INSTALLED_VSCODE=false
if [[ -f "$MANIFEST_FILE" ]]; then
    source "$MANIFEST_FILE"
else
    echo "No install manifest found at $MANIFEST_FILE - assuming install-macos.command never put any system-wide tools in place here, so none of them will be touched."
fi

echo "CT3505-24 uninstaller"
echo "======================"
echo "This will remove:"
echo "  - the '$ENV_NAME' conda environment"
echo "  - $PROJECT_DIR/.env"
[[ "$INSTALLED_SUMO" == "true" ]] && echo "  - SUMO (installed by install-macos.command)"
[[ "$INSTALLED_XQUARTZ" == "true" ]] && echo "  - XQuartz (installed by install-macos.command)"
[[ "$INSTALLED_VSCODE" == "true" ]] && echo "  - Visual Studio Code (installed by install-macos.command)"
[[ "$INSTALLED_MINICONDA" == "true" ]] && echo "  - Miniconda, and ALL conda environments, not just '$ENV_NAME' (installed by install-macos.command)"
[[ "$INSTALLED_ROSETTA" == "true" ]] && echo "  - Rosetta 2 (installed by install-macos.command)"
[[ "$INSTALLED_HOMEBREW" == "true" ]] && echo "  - Homebrew itself, and everything installed through it (installed by install-macos.command)"
echo ""
echo "Anything not listed above was already on your Mac before install-macos.command ran, and will be left alone."
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
# Always removed: this environment name is unique to this course, so it can
# never be something that pre-existed for an unrelated reason.
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
if [[ "$INSTALLED_SUMO" == "true" ]]; then
    step "Removing SUMO (installed by install-macos.command)..."
    for SUMO_PKG_ID in $(pkgutil --pkgs 2>/dev/null | grep -i sumo); do
        echo "Removing files installed by package $SUMO_PKG_ID..."
        remove_pkg_files "$SUMO_PKG_ID"
    done
    rm -rf /usr/local/share/sumo /usr/local/opt/sumo /Applications/sumo /Library/sumo 2>/dev/null
    # The official .pkg installer ships SUMO as a macOS framework bundle plus
    # launcher apps, which may not be fully covered by the package receipt.
    rm -rf "/Library/Frameworks/EclipseSUMO.framework" \
           "/Applications/SUMO sumo-gui.app" "/Applications/SUMO netedit.app" \
           "/Applications/SUMO Scenario Wizard.app" 2>/dev/null
    if command -v brew >/dev/null 2>&1; then
        brew uninstall --cask --zap sumo-gui >/dev/null 2>&1
        brew uninstall --zap sumo >/dev/null 2>&1
        brew untap dlr-ts/sumo >/dev/null 2>&1
    fi
else
    step "Skipping SUMO (not installed by install-macos.command)."
fi

# The SUMO PATH block this project adds to shell startup files is always
# uniquely ours (tagged with "ct3505 sumo path"), so it's safe to remove
# regardless of whether SUMO itself was freshly installed or pre-existing.
step "Removing SUMO PATH entry from shell startup files..."
for RC in "$HOME/.zshrc" "$HOME/.bash_profile"; do
    if [[ -f "$RC" ]] && grep -q "# >>> ct3505 sumo path >>>" "$RC"; then
        sed -i '' '/# >>> ct3505 sumo path >>>/,/# <<< ct3505 sumo path <<</d' "$RC"
    fi
done

# --- 3. XQuartz ---
if [[ "$INSTALLED_XQUARTZ" == "true" ]]; then
    step "Removing XQuartz (installed by install-macos.command)..."
    if command -v brew >/dev/null 2>&1; then
        brew uninstall --cask --zap xquartz 2>/dev/null || echo "XQuartz not installed via Homebrew, skipping."
    fi
else
    step "Skipping XQuartz (not installed by install-macos.command)."
fi

# --- 4. Visual Studio Code ---
if [[ "$INSTALLED_VSCODE" == "true" ]]; then
    step "Removing Visual Studio Code (installed by install-macos.command)..."
    if command -v brew >/dev/null 2>&1; then
        brew uninstall --cask --zap visual-studio-code 2>/dev/null || echo "VS Code not installed via Homebrew, skipping."
    fi
    rm -rf "$HOME/Library/Application Support/Code" "$HOME/.vscode" "$HOME/.vscode-insiders" \
           "/Applications/Visual Studio Code.app" 2>/dev/null
else
    step "Skipping Visual Studio Code (not installed by install-macos.command)."
fi

# --- 5. Miniconda ---
if [[ "$INSTALLED_MINICONDA" == "true" ]]; then
    step "Removing Miniconda (installed by install-macos.command)..."
    if command -v brew >/dev/null 2>&1; then
        brew uninstall --cask --zap miniconda 2>/dev/null || echo "Miniconda not installed via Homebrew, skipping."
    fi
    # Only the Homebrew-cask install path is removed above - never
    # ~/miniconda3 or similar, since install-macos.command never installs
    # there itself, and those paths could belong to an unrelated, manually
    # installed conda that just happened to satisfy the "conda already
    # present" check on some earlier run.
    for RC in "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.bashrc"; do
        if [[ -f "$RC" ]] && grep -q "# >>> conda initialize >>>" "$RC"; then
            sed -i '' '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' "$RC"
        fi
    done
else
    step "Skipping Miniconda (not installed by install-macos.command)."
fi

# --- 6. Rosetta 2 ---
if [[ "$INSTALLED_ROSETTA" == "true" ]]; then
    step "Removing Rosetta 2 (installed by install-macos.command)..."
    softwareupdate --uninstall-rosetta --agree-to-license 2>/dev/null || echo "Could not uninstall Rosetta 2 (it may be in use by other apps, or already removed)."
else
    step "Skipping Rosetta 2 (not installed by install-macos.command)."
fi

# --- 7. Homebrew ---
# Only reached when install-macos.command itself installed Homebrew, which
# means Homebrew did not exist before that run - so nothing pre-existing
# could depend on anything installed through it, and it's safe to remove
# entirely along with everything installed through it.
if [[ "$INSTALLED_HOMEBREW" == "true" ]]; then
    step "Removing Homebrew (installed by install-macos.command)..."
    if command -v brew >/dev/null 2>&1; then
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
    else
        echo "Homebrew not found, skipping."
    fi
else
    step "Skipping Homebrew (not installed by install-macos.command)."
fi

# --- 8. Project files ---
step "Removing $PROJECT_DIR/.env and the install manifest..."
rm -f "$PROJECT_DIR/.env" "$MANIFEST_FILE"

step "Done!"
echo "Anything not removed above (Homebrew, Miniconda, SUMO, XQuartz, VS Code, Rosetta 2) was already on your Mac before install-macos.command ran, and has been left untouched."
echo "You may need to open a new Terminal window for PATH changes to take effect."
read -p $'\nPress Enter to close this window...'
