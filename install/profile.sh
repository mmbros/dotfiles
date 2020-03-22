#!/bin/bash

################
##  .profile  ##
################

COMMENT='# load ~/.profile.d scripts'

# update "~/.profile" file
update_profile() {
  cat >> "$HOME/.profile" << EOF

$COMMENT
if [ -d ~/.profile.d ]; then
  for i in ~/.profile.d/*.sh; do
    if [ -r \$i ]; then
      . \$i
    fi
  done
  unset i
fi
EOF
}

session_start ".profile"


## check if '.profile' file handles '.profile.d' folder
## looking for $COMMENT string
grep "$COMMENT" "$HOME/.profile" >/dev/null
if [ $? -eq 1  ]; then
    ## string not found
    log "update '~/.profile' file in order to load '~/.profile.d folder scripts"
	update_profile
fi

## create ~/.profile.d folder, if not exists
dir="$HOME/.profile.d"
if [[ ! -e "$dir" ]]; then
	log "create \"$dir\" directory"
    mkdir "$dir"
elif [[ ! -d "$dir" ]]; then
	error "$dir already exists but is not a directory"
fi

session_end ".profile"

