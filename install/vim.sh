#!/bin/bash

session_start "VIM"


# 1. install VIM package, if not present

check_installed_package "vim"
if [[ $? -ne 0 ]]; then
  log "install VIM package"
  sudo apt-get install -y -q vim
  if [[ $? -ne 0 ]]; then
	error "Can't install vim package"
  fi
else
  log "VIM package is already installed"
fi

# 2. install vim-plug: Vim plugin manager

fn=~/.vim/autoload/plug.vim
dir=${fn%/*}
if [ -f $fn ]; then
  log "file '$fn' already exists"
else
  log "download 'plug.vim' to '$dir'"
  wget -P $dir https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# 3. backup old .vimrc, if exists

if [ -f ~/.vimrc ]; then
  fn=~/.vimrc.backup.$(date +%F_%R)
  log "backup old '.vimrc' file in '$(basename $fn)'"
  mv ~/.vimrc $fn
fi

# 4. install .vimrc

log "download '.vimrc' to '~'"
wget -P $HOME https://raw.githubusercontent.com/mmbros/dotfiles/master/vim/.vimrc

# 5. start vim executing PlugInstall command non-interactively
#    REF: https://github.com/junegunn/vim-plug/issues/675

log "run PlugInstall not-interactively"

vim +'PlugInstall --sync' +qa

session_end "VIM"
