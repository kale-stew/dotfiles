#!/usr/bin/env bash
#
# set-defaults.sh — configure macOS system defaults
#
# Run this script to set sensible defaults for a new macOS install.
# It's idempotent — safe to re-run at any time.
#
# Based on https://github.com/mathiasbynens/dotfiles/blob/master/.macos

set -e

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "  [skipping] not macOS"
  exit 0
fi

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo timestamp until the script has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" 2>/dev/null || exit
done

# ------------------------------------------------------------------
# Keyboard & Input
# ------------------------------------------------------------------

# Set a fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes and smart quotes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable press-and-hold for keys (enables key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Enable tap to click for trackpad
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

# ------------------------------------------------------------------
# Dock
# ------------------------------------------------------------------

# Set dock icon size
defaults write com.apple.dock tilesize -int 36

# Auto-hide the dock
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay
defaults write com.apple.dock autohide-delay -float 0

# Remove dock hide/show animation
defaults write com.apple.dock autohide-time-modifier -float 0

# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true

# Don't rearrange spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# ------------------------------------------------------------------
# Finder
# ------------------------------------------------------------------

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Disable extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# Show full POSIX path in title bar
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Use list view by default
defaults write com.apple.Finder FXPreferredViewStyle -string "Nlsv"

# Allow quitting Finder with Cmd+Q
defaults write com.apple.finder QuitMenuItem -bool true

# Show the ~/Library folder
chflags nohidden ~/Library

# Avoid creating .DS_Store files on network and USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# ------------------------------------------------------------------
# Desktop
# ------------------------------------------------------------------

# Show hard drives, external disks, and removable media on desktop
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool true

# ------------------------------------------------------------------
# Screenshots
# ------------------------------------------------------------------

# Save screenshots to ~/Screenshots
SCREENSHOT_DIR="$HOME/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"

# Disable screenshot thumbnail preview (macOS 13+)
defaults write com.apple.screencapture show-thumbnail -bool false

# Save screenshots as PNG
defaults write com.apple.screencapture type -string "png"

# ------------------------------------------------------------------
# Window Manager (macOS 15+)
# ------------------------------------------------------------------

# Enable window tiling by dragging to edges
defaults write com.apple.WindowManager EnableTilingByEdgeDrag -bool true

# Enable tiling by holding Option key
defaults write com.apple.WindowManager EnableTilingByOptionDrag -bool true

# Disable Stage Manager
defaults write com.apple.WindowManager GloballyEnabled -bool false

# ------------------------------------------------------------------
# Safari & WebKit
# ------------------------------------------------------------------

# Enable Safari developer menu
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

# Show full URL in Safari address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# ------------------------------------------------------------------
# Misc
# ------------------------------------------------------------------

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true

# Always show scrollbars
defaults write NSGlobalDomain AppleShowScrollBars -string "Always"

# Use AirDrop over all network interfaces
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

# Quit printer app when print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# ------------------------------------------------------------------
# Apply changes
# ------------------------------------------------------------------

echo "  [restarting affected applications]"
for app in "Dock" "Finder" "Safari" "SystemUIServer"; do
  killall "$app" 2>/dev/null || true
done

echo "  [done] some changes require a logout/restart to take effect"
