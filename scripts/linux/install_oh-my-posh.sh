#!/bin/bash

if ! command -v curl &>/dev/null; then
    echo "Error: curl is not installed."
    exit 1
fi

echo "Downloading & installing oh-my-posh"
curl -s https://ohmyposh.dev/install.sh | bash -s -- -d ~/.local/bin
if [[ $? -ne 0 ]]; then
    echo "Failed to install oh-my-posh"
    exit 1
fi

echo "oh-my-posh installed to ~/.local/bin."
exit 0
