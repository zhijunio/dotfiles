#!/usr/bin/env bash
# Bootstrap macOS dev environment and symlink dotfiles into $HOME.
#
#   git clone https://github.com/zhijunio/dotfiles.git ~/.dotfiles
#   cd ~/.dotfiles && DOTFILES_GIT_CRYPT_KEY=~/dotfiles-git-crypt.key ./install.sh
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

copy_file_if_missing() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"

  if [[ -e "$dst" || -L "$dst" ]]; then
    info "Preserving existing $dst"
    return
  fi

  cp "$src" "$dst"
  ok "$dst created from template"
}

configure_homebrew_mirrors() {
  export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.ustc.edu.cn/brew.git"
  export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
  export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_CDN_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
  export HOMEBREW_PIP_INDEX_URL="https://pypi.mirrors.ustc.edu.cn/simple"
}

install_homebrew() {
  local install_script
  export HOMEBREW_INSTALL_FROM_ZIP=1

  if install_script="$(curl -fsSL https://gitee.com/ineo6/homebrew-install/raw/master/install.sh)" &&
    /bin/bash -c "$install_script"; then
    return
  fi

  warn "Homebrew mirror installer failed; retrying with the official installer"
  unset HOMEBREW_BREW_GIT_REMOTE HOMEBREW_CORE_GIT_REMOTE HOMEBREW_API_DOMAIN
  unset HOMEBREW_BOTTLE_DOMAIN HOMEBREW_CDN_DOMAIN HOMEBREW_PIP_INDEX_URL
  install_script="$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  /bin/bash -c "$install_script"
  configure_homebrew_mirrors
}

verify_secrets_unlocked() {
  local git_crypt_key
  git_crypt_key="$(git -C "$DOTFILES_DIR" rev-parse --path-format=absolute \
    --git-path git-crypt/keys/default 2>/dev/null)" || {
    echo "无法读取仓库的 git-crypt 状态：$DOTFILES_DIR" >&2
    exit 1
  }

  if [[ ! -s "$git_crypt_key" && -n "${DOTFILES_GIT_CRYPT_KEY:-}" ]]; then
    info "Unlocking encrypted dotfiles"
    (
      cd "$DOTFILES_DIR"
      git-crypt unlock "$DOTFILES_GIT_CRYPT_KEY"
    )
  fi

  if [[ ! -s "$git_crypt_key" ]]; then
    cat >&2 <<EOF
敏感配置尚未通过 git-crypt 解锁，安装已在创建 symlink 前停止。

请从独立备份恢复密钥，然后任选一种方式继续：
  cd "$DOTFILES_DIR"
  git-crypt unlock ~/dotfiles-git-crypt.key
  ./install.sh

或让安装脚本解锁：
  DOTFILES_GIT_CRYPT_KEY=~/dotfiles-git-crypt.key ./install.sh
EOF
    exit 1
  fi

  if ! ssh-keygen -l -f "$DOTFILES_DIR/.ssh/id_ed25519" >/dev/null 2>&1; then
    echo "解锁后的 .ssh/id_ed25519 不是有效 SSH 私钥，安装已停止。" >&2
    exit 1
  fi

  ok "git-crypt secrets unlocked and SSH private key valid"
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
  configure_homebrew_mirrors

  if ! command -v brew &>/dev/null; then
    install_homebrew
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

link_mise_jdks() {
  if [[ "$(uname -s)" != "Darwin" ]]; then
    return 0
  fi

  if ! command -v mise >/dev/null 2>&1; then
    warn "mise not found; skip linking JDKs"
    return 0
  fi

  local mise_java_dir="$HOME/.local/share/mise/installs/java"
  local jvm_dir="/Library/Java/JavaVirtualMachines"

  # Map: mise version dir -> symlink name
  local -A jdk_links=(
    ["zulu-8.96.0.19"]="zulu-8.jdk"
    ["21.0.2"]="openjdk-21.jdk"
    ["25.0.2"]="openjdk-25.jdk"
  )

  for version in "${!jdk_links[@]}"; do
    local src="${mise_java_dir}/${version}"
    local dst="${jvm_dir}/${jdk_links[$version]}"

    if [[ ! -d "$src" ]]; then
      warn "JDK not installed: $src (run 'mise install' first)"
      continue
    fi

    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
      ok "$dst already linked"
      continue
    fi

    info "Linking $dst -> $src"
    sudo ln -sfn "$src" "$dst"
    ok "$dst -> $src"
  done

  info "Verifying /usr/libexec/java_home..."
  /usr/libexec/java_home -V 2>&1 | while IFS= read -r line; do
    info "  $line"
  done
}

setup_ssh() {
  local ssh_key_path="${SSH_PRIVATE_KEY_FILE:-$HOME/.ssh/id_ed25519}"
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if [[ ! -f "$ssh_key_path" ]]; then
    warn "No SSH private key at $ssh_key_path; generating new key"
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$ssh_key_path" -N ""
    echo "  Add this public key to GitHub: $ssh_key_path.pub"
    echo "  Back up the private key outside this Mac before reinstalling."
  fi

  chmod 600 "$ssh_key_path"
  eval "$(ssh-agent -s)"
  ssh-add "$ssh_key_path"
}

link_dotfiles() {
  echo ""
  echo "--- Symlinks ---"
  echo ""

  link_file "$DOTFILES_DIR/.env" "$HOME/.env"
  link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
  copy_file_if_missing "$DOTFILES_DIR/.zshrc.local.example" "$HOME/.zshrc.local"
  link_file "$DOTFILES_DIR/.aliases" "$HOME/.aliases"
  link_file "$DOTFILES_DIR/.functions" "$HOME/.functions"
  link_file "$DOTFILES_DIR/.zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
  copy_file_if_missing "$DOTFILES_DIR/.gitconfig.local.example" "$HOME/.gitconfig.local"
  copy_file_if_missing "$DOTFILES_DIR/.gitconfig.work.local.example" "$HOME/.gitconfig.work.local"
  link_file "$DOTFILES_DIR/.config/gh/config.yml" "$HOME/.config/gh/config.yml"
  link_file "$DOTFILES_DIR/.config/mise/config.toml" "$HOME/.config/mise/config.toml"
  link_file "$DOTFILES_DIR/.config/starship.toml" "$HOME/.config/starship.toml"
  link_file "$DOTFILES_DIR/.config/ghostty/config" "$HOME/.config/ghostty/config"
  link_file "$DOTFILES_DIR/.config/rclone/rclone.conf" "$HOME/.config/rclone/rclone.conf"
  link_file "$DOTFILES_DIR/.config/git/ignore" "$HOME/.config/git/ignore"
  link_file "$DOTFILES_DIR/.m2/settings.xml" "$HOME/.m2/settings.xml"
  link_file "$DOTFILES_DIR/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ed25519.pub"
  link_file "$DOTFILES_DIR/.ssh/id_ed25519" "$HOME/.ssh/id_ed25519"
  link_file "$DOTFILES_DIR/.wakatime.cfg" "$HOME/.wakatime.cfg"
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
  verify_secrets_unlocked
  link_dotfiles
  setup_ssh
  setup_mise
  link_mise_jdks
  set_default_shell

  echo ""
  echo "Done."
  echo "Reload shell: source ~/.zshrc   # or: exec zsh -l"
}

main "$@"
