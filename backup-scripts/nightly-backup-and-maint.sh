#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

readarray -d '' config_files < <(find . -name 'config-*.sh' -print0)

for config_file in "${config_files[@]}"; do
    ./backup-one-config-file.sh "$config_file"
done
