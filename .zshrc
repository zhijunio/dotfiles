# -----------------------------------------------------------------------------
# 用户配置（aliases, secrets, functions）
# -----------------------------------------------------------------------------
[[ -f ~/.secrets/env ]] && source ~/.secrets/env
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
[[ -f ~/.zsh_aliases ]] && source ~/.zsh_aliases
[[ -f ~/.zsh_functions ]] && source ~/.zsh_functions

# -----------------------------------------------------------------------------
# SDKMAN (brew: tap sdkman/tap && brew install sdkman-cli)
# -----------------------------------------------------------------------------
_sdkman_prefix="$(brew --prefix sdkman-cli 2>/dev/null)" || true
if [[ -n "${_sdkman_prefix}" ]]; then
  export SDKMAN_DIR="${_sdkman_prefix}/libexec"
  [[ -s "${SDKMAN_DIR}/bin/sdkman-init.sh" ]] && source "${SDKMAN_DIR}/bin/sdkman-init.sh"
  # Java HOME（仅当已安装 Java 时设置）
  if [[ -d "${SDKMAN_DIR}/candidates/java/current" ]]; then
    export JAVA_HOME="${SDKMAN_DIR}/candidates/java/current"
    export PATH="${JAVA_HOME}/bin:${PATH}"
  fi
fi
unset _sdkman_prefix

# JVM & Maven 优化参数
export JAVA_OPTS="-Xms1g -Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication"
export MAVEN_OPTS="-Xms1g -Xmx4g -XX:+TieredCompilation -XX:TieredStopAtLevel=1"

# -----------------------------------------------------------------------------
# Node.js (fnm) & pnpm
# -----------------------------------------------------------------------------
if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd)"
fi

export PNPM_HOME="${HOME}/Library/pnpm"
case ":${PATH}:" in
  *":${PNPM_HOME}:"*) ;;
  *) export PATH="${PNPM_HOME}:${PATH}" ;;
esac

export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

# -----------------------------------------------------------------------------
# OrbStack (可选，未安装则忽略)
# -----------------------------------------------------------------------------
[[ -f "${HOME}/.orbstack/shell/init.zsh" ]] && source "${HOME}/.orbstack/shell/init.zsh"

# Shell 插件与 Starship 由 Kaku 内置 Shell Suite 提供（kaku init / TERM_PROGRAM=Kaku）

# -----------------------------------------------------------------------------
# Zsh 补全初始化
# -----------------------------------------------------------------------------
autoload -Uz compinit

zmodload zsh/datetime
if [[ -f ~/.zcompdump-$ZSH_VERSION ]]; then
  compinit -C -d ~/.zcompdump-$ZSH_VERSION
else
  compinit -d ~/.zcompdump-$ZSH_VERSION
fi

# -----------------------------------------------------------------------------
# Zsh 选项优化
# -----------------------------------------------------------------------------
setopt auto_cd              # 直接 cd 到目录名
setopt auto_pushd           # 自动 pushd
setopt pushd_ignore_dups    # 忽略重复目录
setopt pushdminus           # 支持 cd -2 等语法

# -----------------------------------------------------------------------------
# 历史记录优化
# -----------------------------------------------------------------------------
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS    # 删除重复历史
setopt HIST_FIND_NO_DUPS       # 搜索不显示重复
setopt HIST_REDUCE_BLANKS      # 删除空白行
setopt HIST_IGNORE_SPACE       # 忽略空格开头的命令
setopt SHARE_HISTORY           # 多会话共享历史
setopt APPEND_HISTORY          # 追加模式
setopt INC_APPEND_HISTORY      # 立即写入
setopt EXTENDED_HISTORY        # 保存时间戳
