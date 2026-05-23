#!/usr/bin/env bash
#
# install.sh — symlink VS Code settings into the Code user directory
#
# Usage: vscode/install.sh

set -e

VSCODE_USER="$HOME/Library/Application Support/Code/User"
DOTFILES="$(cd "$(dirname "$0")/.." && pwd -P)"

if [[ ! -d "$VSCODE_USER" ]]; then
  echo "  [skipping] VS Code user directory not found at $VSCODE_USER"
  exit 0
fi

for file in settings.json extensions.json; do
  src="$DOTFILES/vscode/$file"
  dst="$VSCODE_USER/$file"

  if [[ -f "$dst" && ! -L "$dst" ]]; then
    mv "$dst" "${dst}.backup"
    echo "  [backup] moved existing $file to ${file}.backup"
  fi

  ln -sf "$src" "$dst"
  echo "  [linked] $file"
done

echo "  [done] VS Code settings installed. Restart VS Code to apply."
