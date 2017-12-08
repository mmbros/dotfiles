#!/usr/bin/env bash

# tmux
tmux_pkg=tmux/.tmux.conf
tmux_sys=~/.tmux.conf

# vim
vim_pkg=vim/.vimrc
vim_sys=~/.vimrc

function usage() {
	echo "$0 install|save"
}

function do_copy() {
	local src="$1"
	local dst="$2"
    if [ ! -f $src ]; then
		echo "ERR  source file not exist: $src"
	elif [ $dst -nt $src ]; then
		echo "SKIP dest file \"$dst\" is newer than source \"$src\""
	else
		echo "COPY \"$src\" -> \"$dst\""
	    cp --update $src $dst
	fi
}


function do_install() {
    # tmux
    do_copy $tmux_pkg $tmux_sys
	# vim
    do_copy $vim_pkg $vim_sys
}

function do_save() {
    # tmux
    do_copy $tmux_sys $tmux_pkg
	# vim
    do_copy $vim_sys $vim_pkg
}


case "$1" in
  install)
  do_install
  exit 0
  ;;

  save)
  do_save
  exit 0
  ;;

  *)
  usage
  exit 1
esac


