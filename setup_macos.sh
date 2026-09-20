#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  return 0
fi

if ! xcode-select -p &>/dev/null; then
  echo "请先安装 Command Line Tools，完成后再运行本脚本："
  echo "  xcode-select --install"
  exit 1
fi

readonly COMPUTER_NAME="${USER}-mac"
readonly TIMEZONE="Asia/Shanghai"
sudo scutil --set ComputerName "$COMPUTER_NAME"
sudo scutil --set HostName "$COMPUTER_NAME"
sudo scutil --set LocalHostName "$COMPUTER_NAME"
sudo systemsetup -settimezone "$TIMEZONE"

defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
defaults write com.apple.dock launchanim -bool false
defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
defaults write com.apple.dock expose-animation-duration -float 0.1
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write com.apple.finder AppleShowAllFiles -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true