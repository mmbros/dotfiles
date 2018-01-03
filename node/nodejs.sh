#!/usr/bin/env bash

# Abort script at first error (when a command exits with non-zero status)
set -e

# Echoes all commands before executing.
# set -v

# Echoes all commands before executing (expands commands).
set -x

##### VARIABLES
NODE_VERSION="8.9.4"
DOWNLOAD_FOLDER="$HOME/Downloads"
INSTALL_PATH="$HOME/.local"

if [ `uname -m` == 'x86_64' ]; then
	ARCH='linux-x64'
else
	ARCH='linux-x86'
fi
NODE_BASE="node-v$NODE_VERSION-$ARCH"
NODE_ARCHIVE="$NODE_BASE.tar.xz"
NODE_PKG="https://nodejs.org/dist/v$NODE_VERSION/$NODE_ARCHIVE"


function do_install {

	# get node package
	wget --no-clobber --directory-prefix="$DOWNLOAD_FOLDER" $NODE_PKG

	# extract files
	tar xf "$DOWNLOAD_FOLDER/$NODE_ARCHIVE" --directory="$INSTALL_PATH" --keep-old-file

	# make symlink '.local/node' -> '.local/node-vX.Y.Z-linux-x99'
	rm -f "$INSTALL_PATH/node"
	ln -rs "$INSTALL_PATH/$NODE_BASE" "$INSTALL_PATH/node"
}


function do_remove {

	# remove symlink
	rm -f "$INSTALL_PATH/node"

	# remove files
	rm -rf "$INSTALL_PATH/$NODE_BASE"

}

function do_usage {
	echo "Usage: ${0##*/} {install|remove}"
}

case "$1" in
	install)
		do_install
		;;
	remove)
		do_remove
    	;;
	*)
		do_usage
		exit 1
		;;
esac

exit 0

