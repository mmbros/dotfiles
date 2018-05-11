#!/bin/bash

# Stop program and give error message
# $1 - error message (string)
error() {
   echo "ERROR: $1"
   exit 1
}

# print a message
# $1 - message (string)
log() {
  echo "$1"
}

# Start session message
# $1 - session (string)
session_start() {
  log "### START $1 ###"
}

# End session message
# $1 - session (string)
session_end() {
  log "### END $1 ###"
}

check_package() {
  # https://stackoverflow.com/questions/1298066/check-if-a-package-is-installed-and-then-install-it-if-its-not
  pkg_name=$1
  pkg_status=$(dpkg-query -W --showformat='${Status}\n' $pkg_name)
  echo $pkg_status
}
