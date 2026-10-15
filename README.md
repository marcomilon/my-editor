# my-editor

My Neovim and tmux configs.

- `nvim/`: a minimal, VS Code-like Neovim setup in a single `init.lua`
- `tmux/`: `tmux.conf`
- `zsh/ws.zsh`: the `ws` command, which opens a project in a tmux workspace

## Requirements

- Neovim 0.11
- tmux 3.1+ (reads `~/.config/tmux/tmux.conf`)
- git, a C compiler (for syntax parsers)
- A [Nerd Font](https://www.nerdfonts.com/) set as the terminal font

## Install

```sh
git clone <this repo> ~/Code/my-editor
~/Code/my-editor/install.sh
nvim
```

`install.sh` symlinks `~/.config/nvim` and `~/.config/tmux` to this repo. Anything already there that isn't a symlink, and any `~/.tmux.conf`, is renamed to `.bak`. Plugins install automatically the first time you open Neovim.

## Neovim

- File tree on the left (neo-tree), open files as tabs on the right (bufferline)
- Source Control view with Staged / Changes lists and side-by-side diffs (diffview)
- Git change markers next to line numbers (gitsigns)
- Tree-sitter syntax highlighting (PHP, Blade, TypeScript, and more)
- VS Code dark theme

### Keys

| Key | Action |
|---|---|
| `Space e` | Show / hide the file tree |
| `Space g` | Open / close Source Control |
| `Shift-l` / `Shift-h` | Next / previous tab |
| `Space x` | Close tab |
| `]c` / `[c` | Next / previous change |
| `Space h p` / `h r` / `h s` | Preview / undo / stage a change |

In Source Control: click a file to see its diff, `-` stages/unstages, `q` closes.

## tmux

Prefix is the default `Ctrl-b`.

| Key | Action |
|---|---|
| `prefix \|` / `prefix -` | Split side by side / top and bottom |
| `prefix h j k l` | Move between panes |
| `prefix H J K L` | Resize pane |
| `prefix r` | Reload config |
| `prefix Esc` | Copy mode (`v` select, `y` copy) |

## Workspace (`ws`)

`ws` opens a project in a tmux session named after its folder: nvim top-left, a shell bottom-left, and claude on the right. If the session already exists, it switches to it instead.

```sh
ws              # current folder
ws my-editor    # ~/Code/my-editor or ~/Code/*/my-editor
ws ~/some/path  # any existing folder
```

Tab completion lists the projects under `~/Code`. To enable it, add this to `~/.zshrc`:

```sh
source ~/Code/my-editor/zsh/ws.zsh
```
