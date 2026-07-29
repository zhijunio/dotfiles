# -----------------------------------------------------------------------------
# zprofile: 登录 shell 环境变量与登录期 PATH
# -----------------------------------------------------------------------------
# 只放登录 shell 需要的环境变量和 PATH，避免污染非交互式 zsh。

if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export HOMEBREW_API_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles/api"
export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.ustc.edu.cn/homebrew-bottles"
export HOMEBREW_PIP_INDEX_URL="https://pypi.mirrors.ustc.edu.cn/simple"
export HOMEBREW_NO_AUTO_UPDATE=1
