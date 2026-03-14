#!/bin/bash
# PhaseFetch installer for non-Arch systems (Debian/Ubuntu, Fedora, etc.)

set -e

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
INSTALL_BIN="/usr/local/bin/phasefetch"
INSTALL_DATA="/usr/share/phasefetch"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}[+]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
error()   { echo -e "${RED}[x]${NC} $1" >&2; exit 1; }

# Check for required tools
info "Checking dependencies..."
for cmd in bash awk file date sleep ln cp mkdir; do
    command -v "$cmd" &>/dev/null || error "Missing required dependency: $cmd"
done

if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
    warn "imagemagick not found — PNG tinting (--color with PNG modes) will be disabled."
fi

if ! command -v fastfetch &>/dev/null; then
    warn "fastfetch not found — PhaseFetch will still work, but you won't be able to display the moon phase in your terminal fetch without it."
    warn "Install it from: https://github.com/fastfetch-cli/fastfetch"
fi

# Check we're running from the project root
if [ ! -f "$SCRIPT_DIR/phasefetch.sh" ]; then
    error "installer must be run from the phasefetch project root (phasefetch.sh not found)"
fi

if [ ! -d "$SCRIPT_DIR/ascii" ] || [ ! -d "$SCRIPT_DIR/png" ]; then
    error "Mode data directories (ascii/, png/) not found. Are you running this from the project root?"
fi

# Install data files
info "Installing mode data to $INSTALL_DATA..."
sudo mkdir -p "$INSTALL_DATA"

for mode_dir in "$SCRIPT_DIR"/*/; do
    mode_name="$(basename "$mode_dir")"
    # Skip non-mode directories
    if [ ! -f "$mode_dir/full_moon" ] && [ ! -f "$mode_dir/new_moon" ]; then
        continue
    fi
    sudo cp -r "$mode_dir" "$INSTALL_DATA/$mode_name"
    info "  Installed mode: $mode_name"
done

# Install the script
info "Installing phasefetch to $INSTALL_BIN..."
sudo cp "$SCRIPT_DIR/phasefetch.sh" "$INSTALL_BIN"
sudo chmod +x "$INSTALL_BIN"

info "Done! phasefetch is installed."
echo ""
echo "  Run it with:  phasefetch --mode ascii"
echo "  Get help with: phasefetch --help"
echo ""

# Offer to install systemd user service
read -rp "Would you like to install a systemd user service so phasefetch starts automatically? [y/N] " install_service
if [[ "$install_service" =~ ^[Yy]$ ]]; then
    SERVICE_DIR="$HOME/.config/systemd/user"
    mkdir -p "$SERVICE_DIR"
    cat > "$SERVICE_DIR/phasefetch.service" <<EOF
[Unit]
Description=PhaseFetch moon phase updater

[Service]
ExecStart=$INSTALL_BIN --mode ascii --update-frequency 8
Restart=on-failure

[Install]
WantedBy=default.target
EOF
    systemctl --user daemon-reload
    systemctl --user enable --now phasefetch.service
    info "Service installed and started."
    info "Edit ~/.config/systemd/user/phasefetch.service to change mode or update frequency."
else
    warn "Skipping service install. See the README for autostart instructions for your DE."
fi

echo ""
info "To integrate with FastFetch, add this to your FastFetch config (~/.config/fastfetch/config.jsonc):"
echo '    "source": "$XDG_RUNTIME_DIR/phasefetch/current_phase"'
