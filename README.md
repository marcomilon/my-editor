# my-editor

A minimal, VS Code-like Neovim setup in a single `init.lua`.

- File tree on the left (neo-tree), open files as tabs on the right (bufferline)
- Source Control view with Staged / Changes lists and side-by-side diffs (diffview)
- Git change markers next to line numbers (gitsigns)
- Tree-sitter syntax highlighting (PHP, Blade, TypeScript, and more)
- VS Code dark theme

## Requirements

- Neovim 0.11
- git, a C compiler (for syntax parsers)
- A [Nerd Font](https://www.nerdfonts.com/) set as the terminal font

## Install

```sh
git clone <this repo> ~/Code/my-editor
ln -s ~/Code/my-editor ~/.config/nvim
nvim
```

Plugins install automatically on first launch.

## Keys

| Key | Action |
|---|---|
| `Space e` | Show / hide the file tree |
| `Space g` | Open / close Source Control |
| `Shift-l` / `Shift-h` | Next / previous tab |
| `Space x` | Close tab |
| `]c` / `[c` | Next / previous change |
| `Space h p` / `h r` / `h s` | Preview / undo / stage a change |

In Source Control: click a file to see its diff, `-` stages/unstages, `q` closes.
