#!/bin/bash

SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
touch $SSH_CONFIG

path=$(pwd)/sources/misc/ssh_shared
if ! grep -q "Include $path" "$SSH_CONFIG" 2>/dev/null; then
    echo "Include $path" >> "$SSH_CONFIG"
fi
chmod 600 "$SSH_CONFIG"

