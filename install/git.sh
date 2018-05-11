#!/bin/bash

session_start "GIT"


# 1. install Git package, if not present

check_or_install_packages "git"

# 2. set git global user.name and user.email

log "set git user.name and user.email"
git config --global user.name "$git_user_name"
git config --global user.email "$git_user_email"

# 3. set git credential.help
#    use libsecret, if possible, else store
#    https://stackoverflow.com/questions/36585496/error-when-using-git-credential-helper-with-gnome-keyring-as-sudo/40312117#40312117 

fn=/usr/share/doc/git/contrib/credential/libsecret/git-credential-libsecret
dir=${fn%/*}
if [ ! -f "$fn" ]; then
  if [ -d "$dir" ]; then
    cd "$dir"
    check_or_install_packages build-essential libsecret-1-0 libsecret-1-dev
    log "sudo make git-credential-libsecret"
    sudo make
  fi
fi

if [ -f $fn ]; then
  log "set git-credential-libsecret"
  git config --global credential.helper "$fn"
else
  log "set git-credential-store"
  git config --global credential.helper store
fi

session_end "GIT"
