#!/bin/sh
# Symlink the configs in this repo to where nvim and tmux look for them.
set -e

repo="$(cd "$(dirname "$0")" && pwd)"

link() {
  src="$repo/$1"
  dest="$2"
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    mv "$dest" "$dest.bak"
    echo "Backed up $dest to $dest.bak"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sfn "$src" "$dest"
  echo "Linked $dest -> $src"
}

link nvim "$HOME/.config/nvim"
link tmux "$HOME/.config/tmux"

# tmux reads ~/.tmux.conf before ~/.config/tmux/tmux.conf, so move it out of the way.
if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
  mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
  echo "Moved ~/.tmux.conf to ~/.tmux.conf.bak"
fi
