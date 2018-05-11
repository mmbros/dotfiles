#!/bin/bash

session_start "GIT"


# 1. install Git package, if not present

check_or_install_package "git"

# 2. git config

log "set git configuration"
git config --global user.name "mmbros"
git config --global user.email "server.mmbros@yandex.com"

# https://stackoverflow.com/questions/36585496/error-when-using-git-credential-helper-with-gnome-keyring-as-sudo/40312117#40312117 
git config --global credential.helper store

session_end "GIT"
