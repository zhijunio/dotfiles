#!/usr/bin/env bash
# Bootstrap macOS dev environment and symlink dotfiles into $HOME.
#
#   git clone git@github.com:zhijunio/dotfiles.git ~/.dotfiles
#   cd ~/.dotfiles && ./install.sh
#
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="$HOME/.secrets"
SECRETS_ENV="${SECRETS_ENV:-$SECRETS_DIR/env}"

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

setup_secrets_dir() {
  if [[ ! -d "$SECRETS_DIR" ]]; then
    mkdir -p "$SECRETS_DIR"
    chmod 700 "$SECRETS_DIR"
    ok "Created $SECRETS_DIR"
  else
    ok "$SECRETS_DIR already exists"
  fi

  if [[ ! -f "$SECRETS_ENV" ]]; then
    warn "$SECRETS_ENV not found"
    echo "  cp \"$DOTFILES_DIR/templates/secrets.env.example\" \"$SECRETS_ENV\""
    echo "  chmod 600 \"$SECRETS_ENV\""
  fi
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

  sudo pwpolicy -clearaccountpolicies
  sudo spctl --master-disable
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

  brew bundle install --file "${DOTFILES_DIR}/Brewfile"
}

setup_sdkman() {
  local _sdkman_prefix
  _sdkman_prefix="$(brew --prefix sdkman-cli 2>/dev/null)" || return 0
  export SDKMAN_DIR="${_sdkman_prefix}/libexec"
  # shellcheck disable=SC1091
  [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
  export SDKMAN_AUTO_ANSWER=true
  sdk install java 25-tem || true
  sdk install java 21-tem || true
  sdk install java 8.0.482-zulu || true
  sdk use java 8.0.482-zulu || true
  sdk install maven || true
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

  link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/.zsh_aliases" "$HOME/.zsh_aliases"
  link_file "$DOTFILES_DIR/.zsh_functions" "$HOME/.zsh_functions"

  link_file "$DOTFILES_DIR/config/kaku/kaku.lua" "$HOME/.config/kaku/kaku.lua"
  link_file "$DOTFILES_DIR/config/git/ignore" "$HOME/.config/git/ignore"
  link_file "$DOTFILES_DIR/config/gh/config.yml" "$HOME/.config/gh/config.yml"
  link_file "$DOTFILES_DIR/config/ssh/config" "$HOME/.ssh/config"
  link_file "$DOTFILES_DIR/ssh/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
}

sync_secrets() {
  if [[ -f "$SECRETS_ENV" ]]; then
    bash "$DOTFILES_DIR/sync-secrets.sh"
  else
    warn "Skipped sync-secrets.sh ($SECRETS_ENV missing)"
  fi
}

source_secrets_env() {
  if [[ ! -f "$SECRETS_ENV" ]]; then
    return 0
  fi
  set -a
  # shellcheck disable=SC1090
  source "$SECRETS_ENV"
  set +a
  ok "Sourced $SECRETS_ENV"
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
  setup_sdkman
  setup_secrets_dir
  link_dotfiles
  sync_secrets
  source_secrets_env
  setup_ssh
  set_default_shell

  local zshrc_local="$HOME/.zshrc.local"
  if [[ ! -f "$zshrc_local" ]] || ! grep -q '^export DOTFILES_DIR=' "$zshrc_local" 2>/dev/null; then
    {
      echo "# Machine-specific zsh overrides (not committed)"
      echo "export DOTFILES_DIR=\"$DOTFILES_DIR\""
    } >> "$zshrc_local"
    chmod 600 "$zshrc_local"
    ok "updated $zshrc_local (DOTFILES_DIR)"
  fi

  echo ""
  echo "Done."
  echo "Reload shell: source ~/.zshrc   # or: exec zsh -l"
}

main "$@"
