export ZSH=$HOME/.dotfiles
export PROJECTS=~/dev

if [[ -a ~/.localrc ]]; then
  source ~/.localrc
fi

typeset -U config_files
config_files=($ZSH/**/*.zsh)

for file in ${(M)config_files:#*/path.zsh}; do
  source $file
done

for file in ${${config_files:#*/path.zsh}:#*/completion.zsh}; do
  source $file
done

autoload -U compinit
compinit

for file in ${(M)config_files:#*/completion.zsh}; do
  source $file
done

unset config_files

# Window title (defined in zsh/window.zsh)
autoload -Uz add-zsh-hook
_set_title_precmd() { title "zsh" "%m" "%55<...<%~" }
add-zsh-hook precmd _set_title_precmd

# Starship prompt
export STARSHIP_CONFIG=$ZSH/starship.toml
if (( $+commands[starship] )); then
  source <(starship init zsh)
fi

# fzf — fuzzy finder history search and file navigation
if [[ -f "$(brew --prefix)/opt/fzf/shell/completion.zsh" ]]; then
  source "$(brew --prefix)/opt/fzf/shell/completion.zsh"
  source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
fi

# zoxide — smart directory jumper
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh)"
fi

# gh — GitHub CLI completions
if (( $+commands[gh] )); then
  source <(gh completion -s zsh)
fi

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
