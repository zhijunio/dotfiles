#!/usr/bin/env bash
# Bootstrap macOS dev environment and symlink dotfiles into $HOME.
#
#   git clone git@github.com:zhijunio/dotfiles.git ~/.dotfiles
#   cd ~/.dotfiles && ./install.sh
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

info() { printf ' [ .. ] %s\n' "$1"; }
ok() { printf ' [ \033[32mOK\033[0m ] %s\n' "$1"; }
warn() { printf ' [ \033[33m!!\033[0m ] %s\n' "$1"; }

link_file() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      ok "$dst already linked"
      return
    fi
    info "Removing stale symlink $dst -> $current"
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    local backup="${dst}.backup.$(date +%Y%m%d%H%M%S)"
    warn "Backing up $dst -> $backup"
    mv "$dst" "$backup"
  fi

  ln -s "$src" "$dst"
  ok "$dst -> $src"
}

setup_macos() {
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
}

setup_homebrew() {
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_CDN_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_PIP_INDEX_URL="https://pypi.mirrors.ustc.edu.cn/simple"

  if ! command -v brew &>/dev/null; then
    export HOMEBREW_INSTALL_FROM_ZIP=1
    /bin/bash -c "$(curl -fsSL https://gitee.com/ineo6/homebrew-install/raw/master/install.sh)"
  fi

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "未找到 brew，请检查安装日志。" >&2
    exit 1
  fi

  local brewfile="${DOTFILES_DIR}/Brewfile"
  local bundle_log="${DOTFILES_DIR}/brew-bundle.log"
  local check_args=(--file "$brewfile" --verbose)
  local install_args=(--file "$brewfile" --verbose --jobs auto)

  echo ""
  echo "--- Homebrew bundle ---"
  info "Brewfile: $brewfile"
  info "log: $bundle_log"
  if [[ "${BREW_BUNDLE_UPGRADE:-}" == "1" ]]; then
    install_args+=(--upgrade)
    info "mode: upgrade + install"
  else
    check_args+=(--no-upgrade)
    install_args+=(--no-upgrade)
    info "mode: install missing only (--no-upgrade)"
  fi
  info "HOMEBREW_NO_AUTO_UPDATE=1"
  echo ""

  export HOMEBREW_NO_AUTO_UPDATE=1
  export HOMEBREW_NO_ENV_HINTS=1

  info "checking Brewfile..."
  brew bundle check "${check_args[@]}" 2>&1 | tee "$bundle_log" || true
  echo ""

  info "installing..."
  brew bundle install "${install_args[@]}" 2>&1 | tee -a "$bundle_log"
  ok "brew bundle done (see $bundle_log)"
}

setup_mise() {
  if ! command -v mise >/dev/null 2>&1; then
    warn "mise not found; skip installing toolchain versions"
    return 0
  fi

  (
    cd "$DOTFILES_DIR"
    mise install -y
  )
}

setup_ssh() {
  local ssh_key_path="${SSH_PRIVATE_KEY_FILE:-$HOME/.ssh/id_ed25519}"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [[ ! -f "$ssh_key_path" ]]; then
    warn "No SSH private key at $ssh_key_path; generating new key"
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$ssh_key_path" -N ""
    echo "  Add to ~/.secrets/env: SSH_PRIVATE_KEY_B64=\$(base64 < \"$ssh_key_path\" | tr -d '\\n')"
  fi

  if [[ -f "$ssh_key_path" ]]; then
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key_path" 2>/dev/null || true
  fi
}

link_dotfiles() {
  echo ""
  echo "--- Symlinks ---"
  echo ""

  link_file "$DOTFILES_DIR/.env" "$HOME/.env"
  link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
  link_file "$DOTFILES_DIR/.functions" "$HOME/.functions"
  link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/.gitconfig_work" "$HOME/.gitconfig_work"
  link_file "$DOTFILES_DIR/.wakatime.cfg" "$HOME/.wakatime.cfg"
  link_file "$DOTFILES_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"

  link_file "$DOTFILES_DIR/.config/rclone/rclone.conf" "$HOME/.config/rclone/rclone.conf"
  link_file "$DOTFILES_DIR/.config/git/ignore" "$HOME/.config/git/ignore"
  link_file "$DOTFILES_DIR/.m2/settings.xml" "$HOME/.m2/settings.xml"
  link_file "$DOTFILES_DIR/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
  link_file "$DOTFILES_DIR/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519"
}

set_default_shell() {
  if [[ "$(uname -s)" == "Darwin" ]] && ! dscl . -read ~/ UserShell | grep -q "/zsh"; then
    info "将默认 shell 切换为 zsh..."
    chsh -s /opt/homebrew/bin/zsh 2>/dev/null || chsh -s /bin/zsh
  fi
}

main() {
  echo ""
  echo "Bootstrapping dotfiles"
  echo "======================"
  echo "DOTFILES_DIR=$DOTFILES_DIR"
  echo ""

  setup_macos
  setup_homebrew
  link_dotfiles
  setup_mise
  setup_ssh
  set_default_shell

  echo ""
  echo "Done."
  echo "Reload shell: source ~/.zshrc   # or: exec zsh -l"
}

main "$@"
