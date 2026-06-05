export EDITOR="nvim"
export VISUAL="nvim"
#------------------------------

[[ -r ~/Repos/znap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/Repos/znap
source ~/Repos/znap/znap.zsh

#-------------------------------


pokeman() {
  print -z "clear; pokemon-colorscripts -r"
  zle .accept-line
}

zle -N pokeman

bindkey '' pokeman


#------------------------------

alias ls='exa --group-directories-first --icons -a'

#------------------------------

alias ff="clear;fastfetch"
alias sp='sudo pacman'
alias p='paru'
alias fl='flatpak'



#------------------------------


alias v='nvim'
alias b='btop'
alias mkd='mkdir'



#------------------------------


eval "$(starship init zsh)"
