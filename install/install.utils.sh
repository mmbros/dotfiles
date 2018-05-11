#!/bin/bash

wget() {
  command wget -q $*
}

# print a message
# $1 - message (string)
log() {
  echo "$1"
}

# Print a warning message
# $1 - warning message (string)
warn() {
   log "WARNING: $1"
}

# Print an error message and stop program
# $1 - error message (string)
error() {
   log "ERROR: $1"
   exit 1
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

# Check if a package is installed. Returns 0 if installed, 1 otherwise
# $1 - package name (string)
# $? - returns 0 if installed, 1 otherwise
check_installed_package() {
  # https://stackoverflow.com/questions/1298066/check-if-a-package-is-installed-and-then-install-it-if-its-not
  pkg_status=$(dpkg-query -W --showformat='${Status}\n' $1)
  if [[ "$pkg_status" == "install ok installed" ]]; then
    return 0
  else
    return 1
  fi
}

# Install a package, if not already installed
# $1 - package name (string)
check_or_install_package() {
  check_installed_package "$1"
  if [[ $? -eq 0 ]]; then
    log "'$1' package is already installed"
  else
    log "install '$1' package"
    sudo apt-get install -y -q "$1"
    if [[ $? -ne 0 ]]; then
      error "can't install '$1 package"
    fi
  fi
}

