# -----------------------------------------------------------------------------
# Shared interactive Zsh configuration
# -----------------------------------------------------------------------------
autoload -Uz compinit

zmodload zsh/datetime
if [[ -f ~/.zcompdump-$ZSH_VERSION ]]; then
  compinit -C -d ~/.zcompdump-$ZSH_VERSION
else
  compinit -d ~/.zcompdump-$ZSH_VERSION
fi

# -----------------------------------------------------------------------------
# Zsh options
# -----------------------------------------------------------------------------
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushdminus

# -----------------------------------------------------------------------------
# History
# -----------------------------------------------------------------------------
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt EXTENDED_HISTORY

# -----------------------------------------------------------------------------
# User commands
# -----------------------------------------------------------------------------
[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.functions ]] && source ~/.functions

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
  maven_bin="$(mise which mvn 2>/dev/null)"
  export MAVEN_HOME="$(dirname "$(dirname "$maven_bin")")"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# OrbStack (optional)
[[ -f "${HOME}/.orbstack/shell/init.zsh" ]] && source "${HOME}/.orbstack/shell/init.zsh"

[[ -f "${HOME}/.zshrc.local" ]] && source "${HOME}/.zshrc.local"

# Keep the command search path stable across nested login shells.
typeset -U path PATH
