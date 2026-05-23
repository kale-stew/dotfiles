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

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
