#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '[bootstrap] %s\n' "$*" >&2; }

bw_get_note() {
  local item="$1" output="$2" error
  if error="$(bw get notes "$item" --session "$BW_SESSION" 2>&1 > "$output")"; then return 0; fi
  [[ -n "$error" ]] && log "警告: Bitwarden 读取失败: $error" || log "警告: Bitwarden 记录不存在或为空，跳过: $item"
  return 1
}

export PATH="$HOME/.local/bin:$PATH"
cd "$ROOT_DIR"

if ! xcode-select -p &>/dev/null; then xcode-select --install; fi
if ! command -v brew &>/dev/null; then
  log "未找到 homebrew，开始安装"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
if ! command -v brew &>/dev/null; then
  for brew_path in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [[ -x "$brew_path" ]]; then
      eval "$("$brew_path" shellenv)"
      break
    fi
  done
fi
command -v brew >/dev/null 2>&1 || { log "未找到 Homebrew"; exit 1; }

if [[ "$(uname -s)" == "Darwin" ]]; then
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle install --file "$ROOT_DIR/Brewfile" --no-upgrade --verbose
fi

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
if [[ ! -r "$OH_MY_ZSH_DIR/oh-my-zsh.sh" ]]; then
  log "安装 Oh My Zsh: $OH_MY_ZSH_DIR"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
fi

SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
export SDKMAN_DIR
SDKMAN_JAVA_8_VERSION="${SDKMAN_JAVA_8_VERSION:-8-zulu}"
SDKMAN_JAVA_21_VERSION="${SDKMAN_JAVA_21_VERSION:-21-tem}"
SDKMAN_JAVA_25_VERSION="${SDKMAN_JAVA_25_VERSION:-25-tem}"
SDKMAN_JAVA_27_VERSION="${SDKMAN_JAVA_27_VERSION:-27-tem}"

BREW_BASH="$(brew --prefix bash)/bin/bash"
"$BREW_BASH" - \
  "$SDKMAN_DIR" \
  "$SDKMAN_JAVA_8_VERSION" \
  "$SDKMAN_JAVA_21_VERSION" \
  "$SDKMAN_JAVA_25_VERSION" \
  "$SDKMAN_JAVA_27_VERSION" <<'SDKMAN_BOOTSTRAP'
set -euo pipefail

SDKMAN_DIR="$1"
export SDKMAN_DIR
if [[ ! -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
  printf '[bootstrap] 未找到 SDKMAN，开始安装\n' >&2
  curl -fsSL https://get.sdkman.io | "$BASH"
fi
source "$SDKMAN_DIR/bin/sdkman-init.sh"

for java_version in "$2" "$3" "$4" "$5"; do
  if [[ ! -d "$SDKMAN_DIR/candidates/java/$java_version" ]]; then
    printf 'n\n' | sdk install java "$java_version"
  fi
done
sdk default java "$4"

if [[ ! -d "$SDKMAN_DIR/candidates/maven/current" ]]; then
  printf 'y\n' | sdk install maven
fi
SDKMAN_BOOTSTRAP

BW_STATUS="$(bw status 2>/dev/null | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')"
[[ "$BW_STATUS" != unauthenticated ]] || bw login

SSH_KEY_ITEM="${BW_SSH_KEY_ITEM:-ssh-macbook-private}"
SSH_KEY="$HOME/.ssh/id_ed25519"
mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
if bw_get_note "$SSH_KEY_ITEM" "$SSH_KEY"; then
  chmod 600 "$SSH_KEY"
  if ! ssh-keygen -y -f "$SSH_KEY" >/dev/null; then
    rm -f "$SSH_KEY"
    echo "ERROR: Bitwarden 条目不是有效的 SSH 私钥: $SSH_KEY_ITEM" >&2
    exit 1
  fi
fi

RCLONE_CONFIG_ITEM="${BW_RCLONE_CONFIG_ITEM:-rclone-config}"
RCLONE_CONFIG="$HOME/.config/rclone/rclone.conf"
mkdir -p "${RCLONE_CONFIG%/*}" && chmod 700 "${RCLONE_CONFIG%/*}"
if bw_get_note "$RCLONE_CONFIG_ITEM" "$RCLONE_CONFIG"; then
  chmod 600 "$RCLONE_CONFIG"
else
  log "警告: 未恢复 rclone 配置，继续执行"
fi

ENV_ITEM="${BW_ENV_ITEM:-dev-env}"
if bw_get_note "$ENV_ITEM" "$HOME/.env"; then
  chmod 600 "$HOME/.env"
  source "$HOME/.env"
else
  log "警告: 未恢复环境变量文件，继续执行"
fi

GITCONFIG_WORK="$HOME/.gitconfig.work"
if [[ -n "${WORK_NAME:-}" && -n "${WORK_EMAIL:-}" ]]; then
  if [[ "$WORK_NAME" == *$'\n'* || "$WORK_EMAIL" == *$'\n'* ]]; then
    log "警告: WORK_NAME 或 WORK_EMAIL 含换行，跳过工作 Git 配置"
  else
    umask 077
    cat > "$GITCONFIG_WORK" <<EOF
[user]
  name = ${WORK_NAME}
  email = ${WORK_EMAIL}
EOF
    chmod 600 "$GITCONFIG_WORK"
  fi
else
  log "警告: WORK_NAME 或 WORK_EMAIL 未设置，跳过工作 Git 配置"
fi

link_dotfile() {
  local source="$ROOT_DIR/$1" target="$HOME/$2"
  mkdir -p "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$(readlink "$target" 2>/dev/null || true)" != "$source" ]]; then
      log "跳过已有配置: $target"
    fi
    return
  fi
  ln -s "$source" "$target"
}

link_dotfile dotfiles/.gitconfig .gitconfig
link_dotfile dotfiles/.aliases .aliases
link_dotfile dotfiles/.functions .functions
link_dotfile dotfiles/.zshrc .zshrc
link_dotfile dotfiles/.zshenv .zshenv
link_dotfile dotfiles/settings.xml .m2/settings.xml
