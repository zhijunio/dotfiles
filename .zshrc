# -----------------------------------------------------------------------------
# zshrc: 交互式 shell 配置、补全、别名和函数
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


# -----------------------------------------------------------------------------
# 用户配置（aliases, functions）
# -----------------------------------------------------------------------------
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.functions ]] && source ~/.functions

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# -----------------------------------------------------------------------------
# OrbStack (可选，未安装则忽略)
# -----------------------------------------------------------------------------
[[ -f "${HOME}/.orbstack/shell/init.zsh" ]] && source "${HOME}/.orbstack/shell/init.zsh"
