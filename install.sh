#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${1:-/usr/local/bin}"

echo "Installing cc-review to $INSTALL_DIR..."

cp "$SCRIPT_DIR/cc-review.sh" "$INSTALL_DIR/cc-review"
chmod +x "$INSTALL_DIR/cc-review"

echo "Installed. Run 'cc-review --help' to get started."
echo ""
echo "Optional: copy the config template:"
echo "  cp $SCRIPT_DIR/.cc-review.conf.example ~/.cc-review.conf"
