#!/bin/bash

wallpaper_url="https://github.com/mmbros/docs/raw/master/img/wallpaperday_by_d0od-d4lhe0g.png"
wallpaper_dir="$HOME/.local/img"

wallpaper_name="${wallpaper_url##*/}"
wallpaper_path="$wallpaper_dir/$wallpaper_name"

session_start "WALLPAPER"

# 1. download wallpaper

log "download wallpaper to '$wallpaper_dir'"
mkdir -p "$wallpaper_dir"
wget -nc -P "$wallpaper_dir" "$wallpaper_url"
if [ $? -ne 0 ]; then
  error "Can't download '$wallpaper_url'"
fi

# 2. set desktop wallpaper

log "set desktop wallpaper"

# set Xfce wallpaper
xfconf-query \
	--channel xfce4-desktop \
	--property /backdrop/screen0/monitor0/workspace0/last-image \
	--set "$wallpaper_path"
if [ $? -ne 0 ]; then
  error "Can't download '$wallpaper_url'"
fi

session_end "WALLPAPER"
