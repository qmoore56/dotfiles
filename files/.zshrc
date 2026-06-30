export EDITOR="nvim"
export VISUAL="nvim"
#------------------------------

[[ -r ~/Repos/znap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/Repos/znap
source ~/Repos/znap/znap.zsh


#------------------------------

alias ls='exa --group-directories-first --icons -a'

#------------------------------

alias ff="clear;fastfetch"
alias sp='sudo pacman'
alias p='paru'
alias fl='flatpak'



#------------------------------


alias v='nvim'
alias sv='sudoedit'
alias b='btop'
alias mkd='mkdir'
alias view='kitty +kitten icat'


#------------------------------


eval "$(starship init zsh)"
