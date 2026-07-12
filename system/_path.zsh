typeset -U path
path=(/opt/homebrew/bin /usr/local/bin /usr/local/sbin /usr/bin /bin /usr/sbin /sbin "$ZSH/bin" $path)
export PATH
export MANPATH="/usr/local/man:/usr/local/mysql/man:/usr/local/git/man:$MANPATH"
