#!/bin/bash

# COMMON FOLDERS (no trailing slash, please)
download_dir="/tmp"
install_base_dir_string='$HOME/.local'
install_base_dir=$(eval "echo $install_base_dir_string")

# GIT
git_user_name="mmbros"
git_user_email="server.mmbros@yandex.com"

# GOLANG
go_pkg_url=https://dl.google.com/go/go1.14.1.linux-amd64.tar.gz
go_pkg_sha256=2f49eb17ce8b48c680cdb166ffd7389702c0dec6effa090c324804a5cac8a7f8

