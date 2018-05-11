#!/bin/bash

##############
##  GOLANG  ##
##############

session_start "GOLANG"

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

## 5. update .profile

log "update '~/.profile' file with GOROOT and GOPATH definitions"
cat >> ~/.profile << EOF

# GOLANG declarations
export GOROOT="$install_base_dir/go"
export GOPATH="\$HOME/Code/go"
EOF

session_end "GOLANG"
