#!/bin/bash

###########
##  VIM  ##
###########

session_start "VIM"

# 1. install VIM package, if not present
check_package "vim"
echo $?
check_package "vim-xxx"
echo $?

# 2. install vim-plug: Vim plugin manager

# log "Download plug.vim and put it in '~/.vim/autoload'"
# wget -P $HOME/.vim/autoload https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

session_end "VIM"
