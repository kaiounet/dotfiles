#!/bin/bash
# scripts/04-fonts.sh
# Font Configuration
# Installs JetBrains Mono fonts and Nerd Fonts

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

section_header "Configuring Fonts..."

# Install JetBrains Mono from DNF
ensure_packages jetbrains-mono-fonts-all

# Set up user font directory
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"

# Check for Nerd Fonts with robust detection
# Look for JetBrainsMono Nerd Font files (e.g., JetBrainsMonoNerdFont-Regular.ttf)
if find "$FONT_DIR" -maxdepth 1 \( -name "*NerdFont*.ttf" -o -name "*NerdFont*.otf" \) 2>/dev/null | grep -q .; then
    info "Nerd Fonts detected in $FONT_DIR. Skipping download."
else
    step "Downloading JetBrains Mono Nerd Font..."
    NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    TMP_ZIP="/tmp/JetBrainsMono.zip"

    if wget -q -O "$TMP_ZIP" "$NERD_FONT_URL"; then
        step "Extracting Nerd Font to $FONT_DIR..."
        unzip -o -q "$TMP_ZIP" -d "$FONT_DIR"
        rm -f "$TMP_ZIP"

        step "Rebuilding font cache..."
        fc-cache -f
        success "Nerd Fonts installed successfully"
    else
        warn "Failed to download Nerd Fonts from $NERD_FONT_URL"
    fi
fi

script_complete "Fonts setup"
