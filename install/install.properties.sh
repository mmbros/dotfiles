#!/bin/bash

# COMMON FOLDERS (no trailing slash, please)
download_dir="/tmp"
install_base_dir="$HOME/DELETE ME"

# strip trailing slash, if present
# download_dir=${download_dir%/}

# GOLANG
go_pkg_url=https://dl.google.com/go/go1.10.2.linux-amd64.tar.gz
go_pkg_sha256=4b677d698c65370afa33757b6954ade60347aaca310ea92a63ed717d7cb0c2ff
