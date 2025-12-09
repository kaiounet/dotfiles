#!/bin/bash
# scripts/06-editors-ides.sh
# Editors & IDEs Installation
# Installs VS Code, Zed, and JetBrains Toolbox

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

DOTFILES_ROOT="$(get_dotfiles_root)"

# ─────────────────────────────────────────────────────────────────────────────
# VS Code
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing VS Code..."

if cmd_exists code; then
    info "VS Code is already installed"
else
    step "Adding Microsoft VS Code repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

    # Create repo file directly (works on all Fedora versions)
    sudo tee /etc/yum.repos.d/vscode.repo > /dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    step "Installing VS Code..."
    sudo dnf install -y code
fi

# ─────────────────────────────────────────────────────────────────────────────
# Zed Editor
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing Zed Editor..."

if cmd_exists zed; then
    info "Zed is already installed"
else
    step "Installing Zed via official installer..."
    curl -f https://zed.dev/install.sh | sh
fi

# ─────────────────────────────────────────────────────────────────────────────
# JetBrains Toolbox
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing JetBrains Toolbox..."

JETBRAINS_DIR="/opt/jetbrains"

if [ -x "$JETBRAINS_DIR/bin/jetbrains-toolbox" ] || cmd_exists jetbrains-toolbox; then
    info "JetBrains Toolbox is already installed"
else
    step "Downloading JetBrains Toolbox..."
    TOOLBOX_URL="https://data.services.jetbrains.com/products/download?code=TBA&platform=linux"
    TMP_TOOLBOX="/tmp/jetbrains-toolbox.tar.gz"

    if wget -q -O "$TMP_TOOLBOX" "$TOOLBOX_URL"; then
        step "Extracting JetBrains Toolbox to $JETBRAINS_DIR..."
        sudo mkdir -p "$JETBRAINS_DIR"
        sudo tar -xzf "$TMP_TOOLBOX" -C "$JETBRAINS_DIR" --strip-components=1
        rm -f "$TMP_TOOLBOX"
        success "JetBrains Toolbox installed"
    else
        warn "Failed to download JetBrains Toolbox"
    fi
fi

# Copy icon to JetBrains Toolbox bin directory if available
ICON_SOURCE="$DOTFILES_ROOT/assets/toolbox.svg"
ICON_DEST="$JETBRAINS_DIR/bin/toolbox.svg"

if [ -f "$ICON_SOURCE" ]; then
    if [ -d "$JETBRAINS_DIR/bin" ] || sudo mkdir -p "$JETBRAINS_DIR/bin"; then
        sudo cp "$ICON_SOURCE" "$ICON_DEST"
        info "JetBrains Toolbox icon installed"
    fi
elif [ -d "$JETBRAINS_DIR" ]; then
    info "No custom Toolbox icon found at $ICON_SOURCE"
fi

script_complete "Editors & IDEs setup"
