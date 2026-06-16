#!/usr/bin/env bash
# Render secret templates into $HOME from ~/.secrets/env (never commit secrets.env).
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_ENV="${SECRETS_ENV:-$HOME/.secrets/env}"

info() { printf ' [ .. ] %s\n' "$1"; }
ok() { printf ' [ \033[32mOK\033[0m ] %s\n' "$1"; }
warn() { printf ' [ \033[33m!!\033[0m ] %s\n' "$1"; }

if [[ ! -f "$SECRETS_ENV" ]]; then
  warn "Missing $SECRETS_ENV"
  echo "  Copy templates/secrets.env.example to ~/.secrets/env and fill in values."
  exit 1
fi

if ! command -v envsubst >/dev/null 2>&1; then
  warn "envsubst not found (brew install gettext)"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$SECRETS_ENV"
set +a

apply_legacy_aliases() {
  # Maven Central
  export MAVEN_CENTRAL_USERNAME="${MAVEN_CENTRAL_USERNAME:-${MAVEN_USERNAME:-}}"
  export MAVEN_CENTRAL_PASSWORD="${MAVEN_CENTRAL_PASSWORD:-${MAVEN_PASSWORD:-}}"

  # Cloudflare R2
  export R2_ENDPOINT="${R2_ENDPOINT:-https://${CF_ACCOUNT_ID:-}.r2.cloudflarestorage.com}"

  # Corporate Nexus (Wesine legacy names)
  export COMPANY_NEXUS_URL="${COMPANY_NEXUS_URL:-${WESINE_NEXUS_URL:-}}"
  export COMPANY_NEXUS_USERNAME="${COMPANY_NEXUS_USERNAME:-${WESINE_NEXUS_USERNAME:-}}"
  export COMPANY_NEXUS_PASSWORD="${COMPANY_NEXUS_PASSWORD:-${WESINE_NEXUS_PASSWORD:-}}"
}

warn_if_empty() {
  local name="$1" value="$2"
  if [[ -z "$value" ]]; then
    warn "unset $name (check $SECRETS_ENV)"
  fi
}

render_template() {
  local template="$1" target="$2" mode="${3:-600}" vars="${4:-}"
  if [[ ! -f "$template" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "$target")"
  if [[ -n "$vars" ]]; then
    envsubst "$vars" < "$template" > "$target"
  else
    envsubst < "$template" > "$target"
  fi
  chmod "$mode" "$target"
  if grep -q '\${' "$target" 2>/dev/null; then
    warn "unexpanded placeholders remain in $target"
  else
    ok "rendered $target"
  fi
}

restore_ssh_private_key() {
  local key_file="${SSH_PRIVATE_KEY_FILE:-$HOME/.ssh/id_ed25519}"
  local key_b64="${SSH_PRIVATE_KEY_B64:-}"

  if [[ -z "$key_b64" ]]; then
    return 0
  fi

  mkdir -p "$(dirname "$key_file")" "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  if printf '%s' "$key_b64" | base64 -d > "$key_file" 2>/dev/null \
    && grep -q 'PRIVATE KEY' "$key_file" 2>/dev/null; then
    chmod 600 "$key_file"
    ok "restored SSH private key to $key_file"
  else
    rm -f "$key_file"
    warn "failed to decode SSH_PRIVATE_KEY_B64"
  fi
}

main() {
  apply_legacy_aliases

  echo ""
  echo "--- Sync secrets ---"
  echo "SECRETS_ENV=$SECRETS_ENV"
  echo ""

  warn_if_empty "GITHUB_USERNAME" "${GITHUB_USERNAME:-}"
  warn_if_empty "GITHUB_EMAIL" "${GITHUB_EMAIL:-}"
  warn_if_empty "COMPANY_USERNAME" "${COMPANY_USERNAME:-}"
  warn_if_empty "COMPANY_EMAIL" "${COMPANY_EMAIL:-}"
  warn_if_empty "WAKATIME_TOKEN" "${WAKATIME_TOKEN:-}"

  render_template \
    "$DOTFILES_DIR/templates/gitconfig.template" \
    "$HOME/.gitconfig" \
    644 \
    '${GIT_HTTP_PROXY} ${GIT_HTTPS_PROXY} ${GITHUB_USERNAME} ${GITHUB_EMAIL}'

  render_template \
    "$DOTFILES_DIR/templates/gitconfig-work.template" \
    "$HOME/.gitconfig_work" \
    600 \
    '${COMPANY_USERNAME} ${COMPANY_EMAIL}'

  render_template \
    "$DOTFILES_DIR/templates/wakatime.cfg.template" \
    "$HOME/.wakatime.cfg" \
    600 \
    '${WAKATIME_TOKEN}'

  render_template \
    "$DOTFILES_DIR/templates/m2-settings.xml.template" \
    "$HOME/.m2/settings.xml" \
    600 \
    '${MAVEN_CENTRAL_USERNAME} ${MAVEN_CENTRAL_PASSWORD} ${COMPANY_NEXUS_USERNAME} ${COMPANY_NEXUS_PASSWORD} ${GITHUB_USERNAME} ${GITHUB_TOKEN} ${SONAR_USERNAME} ${SONAR_TOKEN} ${COMPANY_NEXUS_URL}'

  render_template \
    "$DOTFILES_DIR/templates/rclone.conf.template" \
    "$HOME/.config/rclone/rclone.conf" \
    600 \
    '${R2_ACCESS_KEY_ID} ${R2_SECRET_ACCESS_KEY} ${R2_ENDPOINT}'

  restore_ssh_private_key

  echo ""
  echo "Secrets synced."
}

main "$@"
