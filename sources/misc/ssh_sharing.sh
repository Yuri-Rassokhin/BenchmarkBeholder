#!/bin/bash

SSH_CONFIG="$HOME/.ssh/config"
mkdir -p "$HOME/.ssh"
touch $SSH_CONFIG

path=$(pwd)/sources/misc/ssh_shared
if ! -f "$HOME/.ssh/ssh_shared" 2>/dev/null; then
    cp $path $HOME/.ssh/
    echo "Include ./ssh_shared" >> "$SSH_CONFIG"

fi
chmod 600 $HOME/.ssh/ssh_shared
chown $(whoami):$(whoami) $HOME/.ssh/ssh_shared

