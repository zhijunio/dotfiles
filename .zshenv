# Early environment (login + interactive). Keep machine-specific paths in ~/.zshenv.local
export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_PIP_INDEX_URL="https://pypi.mirrors.ustc.edu.cn/simple"

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

[[ -f "${ZDOTDIR:-$HOME}/.zshenv.local" ]] && source "${ZDOTDIR:-$HOME}/.zshenv.local"
