#!/usr/bin/env bash
#
# install.sh — symlink opencode config, agents, and skills into ~/.config/opencode/
#
# Usage: opencode/install.sh

set -e

OPENCODE_CONFIG_DIR="$HOME/.config/opencode"
DOTFILES="$(cd "$(dirname "$0")/.." && pwd -P)"

if [[ ! -d "$OPENCODE_CONFIG_DIR" ]]; then
  mkdir -p "$OPENCODE_CONFIG_DIR"
  echo "  [created] $OPENCODE_CONFIG_DIR"
fi

# opencode.jsonc
src="$DOTFILES/opencode/opencode.jsonc"
dst="$OPENCODE_CONFIG_DIR/opencode.jsonc"

if [[ -f "$dst" && ! -L "$dst" ]]; then
  mv "$dst" "${dst}.backup"
  echo "  [backup] moved existing opencode.jsonc to opencode.jsonc.backup"
fi

ln -sf "$src" "$dst"
echo "  [linked] opencode.jsonc"

# agents/
agents_src="$DOTFILES/opencode/agents"
agents_dst="$OPENCODE_CONFIG_DIR/agents"

if [[ -d "$agents_dst" && ! -L "$agents_dst" ]]; then
  mv "$agents_dst" "${agents_dst}.backup"
  echo "  [backup] moved existing agents/ to agents.backup"
fi

ln -sf "$agents_src" "$agents_dst"
echo "  [linked] agents/"

# skills/
skills_src="$DOTFILES/opencode/skills"
skills_dst="$OPENCODE_CONFIG_DIR/skills"

if [[ -d "$skills_dst" && ! -L "$skills_dst" ]]; then
  mv "$skills_dst" "${skills_dst}.backup"
  echo "  [backup] moved existing skills/ to skills.backup"
fi

ln -sf "$skills_src" "$skills_dst"
echo "  [linked] skills/"

echo "  [done] Opencode config, agents, and skills installed."
