# Order matters: fpath before oh-my-zsh (it runs compinit), precmd hooks after.
[ -d /opt/homebrew/share/zsh/site-functions ] && fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
[ -d "$HOME/.docker/completions" ] && fpath=("$HOME/.docker/completions" $fpath)

export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME="robbyrussell"   # change me
plugins=(git)              # change me
[ -r "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

command -v direnv >/dev/null && eval "$(direnv hook zsh)"

[[ -f "${HOME}/.orbstack/shell/init.zsh" ]] && source "${HOME}/.orbstack/shell/init.zsh"

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

[[ -f ~/.aliases ]] && source ~/.aliases
[[ -f ~/.functions ]] && source ~/.functions

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
