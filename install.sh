#!/bin/bash

# Symlink config files
ln -sf $(pwd)/.config/fontconfig ~/.config/
ln -sf $(pwd)/.config/gtk-3.0 ~/.config/
ln -sf $(pwd)/.config/gtk-4.0 ~/.config/
ln -sf $(pwd)/.config/hypr ~/.config/
ln -sf $(pwd)/.config/kitty ~/.config/
ln -sf $(pwd)/.config/nvim ~/.config/
ln -sf $(pwd)/.config/nwg-look ~/.config/
ln -sf $(pwd)/.config/rofi ~/.config/
ln -sf $(pwd)/.config/swaync ~/.config/
ln -sf $(pwd)/.config/waybar ~/.config/
ln -sf $(pwd)/.config/yazi ~/.config/
ln -sf $(pwd)/.config/ncmpcpp ~/.config/
ln -sf $(pwd)/.config/mpd ~/.config/
ln -sf $(pwd)/.local/share/fonts ~/.local/share/
ln -sf $(pwd)/.local/share/icons ~/.local/share/
ln -sf $(pwd)/.local/share/themes ~/.local/share/

# Symlink home directory files
ln -sf $(pwd)/.zshrc ~/
ln -sf $(pwd)/.gtkrc ~/

# System themes (requires sudo)
echo "To install system themes, run these commands manually with sudo:"
echo "sudo ln -sf $(pwd)/usr/share/themes/* /usr/share/themes/"
echo "sudo ln -sf $(pwd)/usr/share/icons/* /usr/share/icons/"

echo "Dotfiles installation complete!"
