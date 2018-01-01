#!/usr/bin/env bash

# Abort script at first error (when a command exits with non-zero status)
set -e

# Echoes all commands before executing.
# set -v

# Echoes all commands before executing (expands commands).
set -x

##### VARIABLES
NODE_VERSION="8.9.3"
NODE_PKG="https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz"
DOWNLOAD_FOLDER="$HOME/Downloads"
INSTALL_PATH="$HOME/.local"

NODE_ARCHIVE=${NODE_PKG##*/}

# get node package
wget --no-clobber --directory-prefix="$DOWNLOAD_FOLDER" $NODE_PKG

# extract files
tar xf "$DOWNLOAD_FOLDER/$NODE_ARCHIVE" --directory="$INSTALL_PATH" --keep-old-file

# make symlink '.local/node' -> '.local/node-v8.9.3-linux-x64'
ln -frs "$INSTALL_PATH/${NODE_ARCHIVE%.*.*}" "$INSTALL_PATH/node"


echo """Done.
Remember to add the following lines to .profile file:

# set PATH so it includes "node/bin" folder
if [ -d "$INSTALL_PATH/node/bin" ]; then
    PATH="\$PATH:$INSTALL_PATH/node/bin"
fi
"""
