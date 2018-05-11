#!/bin/bash

session_start "VIM"


# 1. install Vim package, if not present

check_or_install_package "vim"

# 2. install vim-plug: Vim plugin manager

fn=~/.vim/autoload/plug.vim
dir=${fn%/*}
if [ -f $fn ]; then
  log "'plug.vim' already exists in '$dir'"
else
  log "download 'plug.vim' to '$dir'"
  wget -P $dir https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# 3. backup .vimrc, if exists

if [ -f ~/.vimrc ]; then
  fn=~/.vimrc.backup.$(date +%F_%R)
  log "backup '.vimrc' file in '$(basename $fn)'"
  mv ~/.vimrc $fn
fi

# 4. install .vimrc

log "download '.vimrc' to '$HOME'"
wget -P $HOME https://raw.githubusercontent.com/mmbros/dotfiles/master/vim/.vimrc

# 5. start vim executing PlugInstall command non-interactively
#    REF: https://github.com/junegunn/vim-plug/issues/675

log "run PlugInstall not-interactively"
vim +'PlugInstall --sync' +qa

session_end "VIM"
