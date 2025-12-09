#!/bin/bash
# scripts/lib/common.sh
# Common functions and variables for all setup scripts
# Source this file at the top of each script:
#   SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#   source "$SCRIPT_DIR/lib/common.sh"

# Prevent multiple sourcing
if [ -n "${_DOTFILES_COMMON_LOADED:-}" ]; then
    return 0
fi
_DOTFILES_COMMON_LOADED=1

# ─────────────────────────────────────────────────────────────────────────────
# Colors
# ─────────────────────────────────────────────────────────────────────────────
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export RED='\033[0;31m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────────────────────
# Logging functions
# ─────────────────────────────────────────────────────────────────────────────
info()    { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
err()     { echo -e "${RED}[ERROR]${NC} $*"; }
step()    { echo -e "${BLUE}[→]${NC} $*"; }
success() { echo -e "${GREEN}[✓]${NC} $*"; }
header()  { echo -e "${GREEN}[*]${NC} ${BOLD}$*${NC}"; }

# ─────────────────────────────────────────────────────────────────────────────
# Path helpers
# ─────────────────────────────────────────────────────────────────────────────

# Get the directory of the calling script
# Get the directory of the calling script
# Note: This uses BASH_SOURCE[1] to get the caller's location, not common.sh's location
get_script_dir() {
    local source="${BASH_SOURCE[1]}"
    local dir
    # Resolve symlinks if necessary
    while [ -L "$source" ]; do
        dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

# Get the dotfiles repository root (assumes scripts are in dotfiles/scripts/)
# This is based on where common.sh lives (scripts/lib/), not the calling script
get_dotfiles_root() {
    # BASH_SOURCE[0] is this file (common.sh), which lives in scripts/lib/
    local common_sh_dir
    common_sh_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # Go up two levels: lib/ -> scripts/ -> dotfiles/
    cd "$common_sh_dir/../.." && pwd
}

# ─────────────────────────────────────────────────────────────────────────────
# Backup utilities
# ─────────────────────────────────────────────────────────────────────────────

# Backup a file with timestamp
# Usage: backup_file /path/to/file
# Returns: path to backup file, or empty string if nothing to backup
backup_file() {
    local file="$1"
    local backup
    if [ -e "$file" ] || [ -L "$file" ]; then
        backup="${file}.bak.$(date +%Y%m%d%H%M%S)"
        mv "$file" "$backup"
        info "Backed up $file → $backup"
        echo "$backup"
    fi
}

# Backup a directory with timestamp (copies, doesn't move)
# Usage: backup_dir /path/to/dir
# Returns: path to backup dir, or empty string if nothing to backup
backup_dir() {
    local dir="$1"
    local backup
    if [ -d "$dir" ]; then
        backup="${dir}.bak.$(date +%Y%m%d%H%M%S)"
        cp -a "$dir" "$backup"
        info "Backed up $dir → $backup"
        echo "$backup"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Symlink utilities
# ─────────────────────────────────────────────────────────────────────────────

# Create a symlink with backup of existing file
# Usage: safe_symlink /path/to/source /path/to/destination
# Returns: 0 if link created, 1 if already correct
safe_symlink() {
    local src="$1"
    local dest="$2"

    # Check if source exists
    if [ ! -e "$src" ]; then
        err "Source does not exist: $src"
        return 2
    fi

    # Already a symlink pointing to the right place?
    if [ -L "$dest" ]; then
        local current_target
        current_target="$(readlink -f "$dest")"
        local expected_target
        expected_target="$(readlink -f "$src")"
        if [ "$current_target" = "$expected_target" ]; then
            info "$dest already symlinked correctly"
            return 1
        fi
    fi

    # Backup existing file/symlink if present
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        backup_file "$dest"
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dest")"

    # Create symlink
    ln -sfn "$src" "$dest"
    info "Linked $dest → $src"
    return 0
}

# Copy file with backup of existing file
# Usage: safe_copy /path/to/source /path/to/destination
# Returns: 0 if copied, 1 if identical
safe_copy() {
    local src="$1"
    local dest="$2"

    # Check if source exists
    if [ ! -e "$src" ]; then
        err "Source does not exist: $src"
        return 2
    fi

    # Check if destination exists and is identical
    if [ -f "$dest" ] && cmp -s "$src" "$dest"; then
        info "$dest is already identical to $src"
        return 1
    fi

    # Backup existing file if present and different
    if [ -e "$dest" ]; then
        backup_file "$dest"
    fi

    # Ensure parent directory exists
    mkdir -p "$(dirname "$dest")"

    # Copy file
    cp -a "$src" "$dest"
    info "Copied $src → $dest"
    return 0
}

# ─────────────────────────────────────────────────────────────────────────────
# Command availability checks
# ─────────────────────────────────────────────────────────────────────────────

# Check if a command exists
# Usage: cmd_exists git
cmd_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Require a command to exist, exit if not
# Usage: require_cmd git "Please install git first"
require_cmd() {
    local cmd="$1"
    local msg="${2:-$cmd is required but not installed}"
    if ! cmd_exists "$cmd"; then
        err "$msg"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# DNF/Package manager helpers
# ─────────────────────────────────────────────────────────────────────────────

# Check if a DNF package is installed
# Usage: pkg_installed httpd
pkg_installed() {
    rpm -q "$1" >/dev/null 2>&1
}

# Install packages if not already installed
# Usage: ensure_packages git curl wget
ensure_packages() {
    local to_install=()
    for pkg in "$@"; do
        if ! pkg_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done

    if [ ${#to_install[@]} -gt 0 ]; then
        step "Installing: ${to_install[*]}"
        sudo dnf install -y "${to_install[@]}"
    else
        info "All packages already installed: $*"
    fi
}

# Add a DNF repository from a URL (handles both old and new syntax)
# Usage: add_dnf_repo "https://example.com/repo.repo"
add_dnf_repo() {
    local repo_url="$1"
    local repo_name
    repo_name="$(basename "$repo_url" .repo)"

    # Check if repo already exists
    if [ -f "/etc/yum.repos.d/${repo_name}.repo" ]; then
        info "Repository $repo_name already configured"
        return 0
    fi

    step "Adding repository: $repo_name"
    # Use curl to download directly (works on all Fedora versions)
    sudo curl -fsSL -o "/etc/yum.repos.d/${repo_name}.repo" "$repo_url"
}

# ─────────────────────────────────────────────────────────────────────────────
# Flatpak helpers
# ─────────────────────────────────────────────────────────────────────────────

# Install a Flatpak app if not already installed
# Usage: ensure_flatpak com.example.App
ensure_flatpak() {
    local app_id="$1"
    if flatpak info "$app_id" >/dev/null 2>&1; then
        info "Flatpak $app_id already installed"
        return 0
    fi
    step "Installing Flatpak: $app_id"
    flatpak install -y flathub "$app_id"
}

# ─────────────────────────────────────────────────────────────────────────────
# User interaction
# ─────────────────────────────────────────────────────────────────────────────

# Prompt for yes/no confirmation
# Usage: confirm "Do you want to continue?" && do_something
confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-n}"

    local yn_prompt
    if [ "$default" = "y" ]; then
        yn_prompt="[Y/n]"
    else
        yn_prompt="[y/N]"
    fi

    read -r -p "$prompt $yn_prompt " response
    response="${response:-$default}"

    case "$response" in
        [yY][eE][sS]|[yY]) return 0 ;;
        *) return 1 ;;
    esac
}

# ─────────────────────────────────────────────────────────────────────────────
# Script completion banner
# ─────────────────────────────────────────────────────────────────────────────

# Print a completion message for a script
# Usage: script_complete "System core"
script_complete() {
    local name="${1:-Setup}"
    echo -e "${GREEN}✅ ${name} complete${NC}"
}

# Print a section header
# Usage: section_header "Installing packages"
section_header() {
    echo -e "${GREEN}[*]${NC} ${BOLD}$*${NC}"
}
