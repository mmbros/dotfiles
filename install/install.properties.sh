#!/bin/bash

# COMMON FOLDERS (no trailing slash, please)
download_dir="/tmp"
install_base_dir_string='$HOME/.local'
install_base_dir=$(eval "echo $install_base_dir_string")

# GIT
git_user_name="mmbros"
git_user_email="server.mmbros@yandex.com"

# GOLANG
go_pkg_url=https://dl.google.com/go/go1.11.5.linux-amd64.tar.gz
go_pkg_sha256=ff54aafedff961eb94792487e827515da683d61a5f9482f668008832631e5d25

