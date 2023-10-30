#!/bin/sh

current_dir=$(pwd)
test_dir=$(mktemp -d)

cd "$test_dir" || return

# Create a base project based on the pre-FrankenPhp version of symfony-docker template
git clone https://github.com/dunglas/symfony-docker project/
cd project/ || return
git reset --hard b5710da

# Run the script
"$current_dir"/template-sync.sh https://github.com/dunglas/symfony-docker --debug

# Check if docker directory has been replaced by frankenphp directory as intended
if [ -d "frankenphp" ] && [ ! -d "docker"  ]; then
  exit 0     
else
  exit 1
fi





