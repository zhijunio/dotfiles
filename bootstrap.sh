#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log() { printf '[bootstrap] %s\n' "$*" >&2; }

BW_STATUS="$(bw status 2>/dev/null | sed -n 's/.*"status":"\([^"]*\)".*/\1/p')"
[[ "$BW_STATUS" != unauthenticated ]] || bw login
BW_SESSION="$(bw unlock --raw)"
export BW_SESSION
bw sync --session "$BW_SESSION" >/dev/null || log "警告: Bitwarden 同步失败，继续使用本地缓存"

bw_get_note() {
  local item="$1" output="$2" error
  if error="$(bw get notes "$item" --session "$BW_SESSION" 2>&1 > "$output")"; then return 0; fi
  [[ -n "$error" ]] && log "警告: Bitwarden 读取失败: $error" || log "警告: Bitwarden 记录不存在或为空，跳过: $item"
  return 1
}

export PATH="$HOME/.local/bin:$PATH"
export MISE_DATA_DIR="${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}"
export PATH="$MISE_DATA_DIR/shims:$PATH"
export MISE_EXPERIMENTAL=1
cd "$ROOT_DIR"

if ! xcode-select -p &>/dev/null; then xcode-select --install; fi
if ! command -v brew &>/dev/null; then
  log "未找到 homebrew，开始安装"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
if [[ ! -r "$OH_MY_ZSH_DIR/oh-my-zsh.sh" ]]; then
  log "安装 Oh My Zsh: $OH_MY_ZSH_DIR"
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
fi

if ! command -v mise &>/dev/null; then
  log "未找到 mise，开始安装"
  curl -fsSL https://mise.run | sh
fi
if ! command -v bw &>/dev/null; then
  log "未找到 Bitwarden CLI，开始安装"
  brew install bitwarden-cli >/dev/null
fi

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

ENV_ITEM="${BW_ENV_ITEM:-mise-env}"
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

mise trust >/dev/null
mise bootstrap --yes
