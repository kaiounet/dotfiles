#!/bin/bash
# scripts/10-user-apps.sh
# User Applications & Browsers
# Installs Flatpak apps, LibreOffice, LibreWolf, and Brave Browser

set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# ─────────────────────────────────────────────────────────────────────────────
# Flatpak Setup
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing Flatpak Apps..."

# Ensure Flathub remote is configured
if ! flatpak remote-list | grep -q flathub; then
    step "Adding Flathub remote..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    info "Flathub remote already configured"
fi

# Install Flatpak applications
ensure_flatpak com.bitwarden.desktop
ensure_flatpak com.mattjakeman.ExtensionManager
ensure_flatpak org.libreoffice.LibreOffice

# ─────────────────────────────────────────────────────────────────────────────
# LibreWolf Browser
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing LibreWolf..."

LIBREWOLF_REPO="/etc/yum.repos.d/librewolf.repo"

if cmd_exists librewolf; then
    info "LibreWolf is already installed"
else
    if [ ! -f "$LIBREWOLF_REPO" ]; then
        step "Adding LibreWolf repository..."
        # Download repo file directly (works on all Fedora versions)
        sudo curl -fsSL -o "$LIBREWOLF_REPO" https://rpm.librewolf.net/librewolf.repo
    fi

    step "Installing LibreWolf..."
    sudo dnf install -y librewolf
fi

# ─────────────────────────────────────────────────────────────────────────────
# Brave Browser
# ─────────────────────────────────────────────────────────────────────────────
section_header "Installing Brave Browser..."

BRAVE_REPO="/etc/yum.repos.d/brave-browser.repo"

if cmd_exists brave-browser; then
    info "Brave Browser is already installed"
else
    if [ ! -f "$BRAVE_REPO" ]; then
        step "Adding Brave Browser repository..."
        # Download repo file directly (works on all Fedora versions)
        sudo curl -fsSL -o "$BRAVE_REPO" https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

        step "Importing Brave GPG key..."
        sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    fi

    step "Installing Brave Browser..."
    sudo dnf install -y brave-browser
fi

script_complete "User apps setup"
