#!/bin/bash

##############
##  GOLANG  ##
##############

session_start "GOLANG"


## 0. exit if go command already exists

command -v go
if [ $? -eq 0 ]; then
  log "golang command already installed"
  session_end "GOLANG"
  return 0
fi

## 1. download

# downloaded file full pathname
fn="$download_dir/$(basename $go_pkg_url)"

log "download golang package '$(basename $go_pkg_url)' to folder '$download_dir'"
# wget -nc -O $fn $go_pkg_url   # with -O option, returns an error if file already exists
wget -nc -P $download_dir $go_pkg_url
if [ $? -ne 0 ]; then
  error "can't download golang package"
fi

## 2. check sha256 signature

if [ -n "$go_pkg_sha256" ]; then
  log "check golang package sha256 signature is '$go_pkg_sha256'"
  if !( sha256sum "$fn" | grep -Eo '^\w+' | cmp -s <(echo $go_pkg_sha256) ); then
    error "golang package has wrong signature"
  fi
else
  log "skipping golang package sha256 signature check: '\$go_pkg_sha256' is empty"
fi

## 3. extract

log "extract golang package to '$install_base_dir'"
mkdir -p "$install_base_dir/bin"
tar -C "$install_base_dir" -xzf $fn
if [ $? -ne 0 ]; then
  error "can't extract golang package"
fi

## 4. create bin symlinks

log "create symlinks for golang binaries in '$install_base_dir/bin'"
for i in "$install_base_dir"/go/bin/*; do
  ln -s "$i" "$install_base_dir"/bin/$(basename "$i");
done

## 5. insert golang.sh in .profile.d
fn="$HOME/.profile.d/golang.sh"
if [[ ! -e "$fn" ]]; then
    log "create '$fn' file with GOROOT and GOPATH definitions"
    cat >> "$fn" << EOF
# GOLANG declarations
export GOROOT="$install_base_dir_string/go"
export GOPATH="\$HOME/Code/go"
EOF
fi

# 6. create folder and symlink to ~/Code/go/src/github.com/mmbro 
mkdir -p ~/Code/go/src/github.com/mmbros
ln -s ~/Code/go/src/github.com/mmbros ~/mmbros

# 7. start vim executing vim-go's GoInstallBinaries  command non-interactively

log "run GoInstallBinaries not-interactively"
vim +'GoInstallBinaries --sync' +qa

session_end "GOLANG"

