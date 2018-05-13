#!/bin/bash

# name of the properties file
file_properties="install.properties.sh"
file_utils="install.utils.sh"


# source the utils
. $file_utils
if [ $? -ne 0 ]; then
  echo "Can't read file utils!"
  exit 1
fi

# source the properties
. $file_properties
if [ $? -ne 0 ]; then
  error "Can't read file properties!"
fi

# . golang.sh
# . git.sh
# . vim.sh
. wallpaper.sh
