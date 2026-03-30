#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${1:-/usr/local/bin}"

echo "Installing loopwise to $INSTALL_DIR..."

cp "$SCRIPT_DIR/loopwise.sh" "$INSTALL_DIR/loopwise"
chmod +x "$INSTALL_DIR/loopwise"

echo "Installed. Run 'loopwise --help' to get started."
echo ""
echo "Optional: copy the config template:"
echo "  cp $SCRIPT_DIR/.loopwise.conf.example ~/.loopwise.conf"
