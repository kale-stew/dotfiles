# dotfiles

Personal shell and editor configuration, managed with GNU Stow.

## Prerequisites

- **macOS** or **Linux**
- **Git** (to clone the repo)
- **curl** (for Homebrew installation on macOS)

No other tools are required — `script/bootstrap` will install everything it needs.

## Quick start

```sh
git clone https://github.com/kale-stew/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

After bootstrap completes, restart your shell or run `source ~/.zshrc`.

### What bootstrap does

1. Installs **GNU Stow** (via Homebrew on macOS, or apt/pacman/dnf on Linux)
2. Creates `~/.dotfiles/git/gitconfig.local.symlink` from the example template
   if it doesn't exist — **edit this file with your name, email, and SSH signing key**
3. Runs `stow -R home/` to symlink all config files into your home directory
4. On macOS: installs Homebrew (if missing) and runs `brew bundle` to install
   all packages and applications listed in the Brewfile

### Post-install

1. **Edit your git identity** (required):

   ```sh
   code ~/.dotfiles/git/gitconfig.local.symlink
   ```

   Set your name, email, and SSH signing key path.

2. **Configure SSH signing** (recommended):

   Add your SSH public key to GitHub's [signing keys](https://github.com/settings/keys)
   (separate from authentication keys):

   ```sh
   # Add to GitHub SSH keys as a Signing Key (not just Authentication Key)
   pbcopy < ~/.ssh/id_ed25519.pub   # macOS
   ```

   Then verify commits show as "Verified" on GitHub.

3. **Install VS Code settings** (optional):

   ```sh
   ~/.dotfiles/vscode/install.sh
   ```

4. **Apply macOS system defaults** (optional, macOS only):

   ```sh
   ~/.dotfiles/macos/set-defaults.sh
   ```

## What you get

### Prompt

Your shell prompt looks like this after setup:

```
username at hostname in ~/project on main
›
```

Node and npm versions appear on the right side. Git branch colors: green (clean),
red (dirty with ✗). Powered by [Starship](https://starship.rs).

### Shell features

| Feature | What it does |
|---------|-------------|
| `Ctrl-R` | Fuzzy search shell history (via fzf) |
| `Ctrl-T` | Fuzzy search files to paste on command line (via fzf) |
| `Alt-C` | Fuzzy cd into subdirectories (via fzf) |
| `z <fragment>` | Jump to a directory you've visited (via zoxide) |
| `zi` | Interactive directory selection (via zoxide) |
| `..` / `...` | Navigate up directories |
| `reload!` | Reload .zshrc |
| Up/Down arrow | Prefix-based history search |
| `glog` | Pretty git log graph |
| `gs` / `gb` / `gc` / `gco` | Git shortcuts |

### Git

- All commits and tags are **SSH-signed** by default
- `pull.rebase=true` — rebase instead of merge on pull
- `rerere.enabled=true` — automatically resolve recurring merge conflicts
- `rebase.updateRefs=true` — preserve stacked branches during rebase
- `gh` aliases for GitHub workflow (PRs, issues, actions)

### VS Code

If you run `vscode/install.sh`, your VS Code gets:

- Sensible editor defaults (font, formatting, file handling)
- Git commit signing enabled in the editor
- Recommended extensions (Catppuccin theme, Prettier, ESLint, Tailwind CSS,
  GitHub Actions, GitLens, spell checker)

### macOS defaults

Running `macos/set-defaults.sh` configures:

- Fast keyboard repeat, tap-to-click, disable auto-substitutions
- Auto-hiding Dock with no delay or animation
- Finder: path bar, status bar, full POSIX path, list view, ~/Library visible
- Screenshots saved to ~/Screenshots as PNG (no thumbnail preview)
- Window tiling by edge drag (macOS 15+)
- Safari developer menu
- No .DS_Store on network/USB volumes

## File structure

```
~/.dotfiles/
├── home/                        # Stowed to ~/
│   ├── .zshrc                   # Shell entry point — sources all topics
│   ├── .gitconfig               # Git configuration
│   └── .config/git/
│       ├── ignore               # Global gitignore patterns
│       └── attributes           # Global gitattributes
├── starship.toml                # Prompt configuration
├── Brewfile                     # Homebrew packages and apps
├── bin/                         # Scripts added to $PATH
├── script/
│   ├── bootstrap                # One-command setup script
│   └── install                  # Runs Brewfile + topic installers
├── zsh/                         # Zsh config (aliases, completions, key bindings)
├── git/                         # Git aliases, completions, local config template
├── vscode/                      # VS Code settings and install script
├── macos/                       # macOS defaults script
├── functions/                   # Shell functions
├── node/                        # NVM setup
├── system/                      # PATH, env vars, key aliases
├── osx/                         # macOS aliases
├── docker/                      # Docker aliases
├── yarn/                        # Yarn PATH
└── AGENTS.md                    # Context for AI coding assistants
```

Each topic directory can contain:

| File | Purpose |
|------|---------|
| `*.zsh` | Auto-loaded into your shell |
| `path.zsh` | Loaded first — sets `$PATH` or similar |
| `completion.zsh` | Loaded last — sets up autocompletion |
| `install.sh` | Run by `script/install` for tool setup |

### How Zsh loading works

`~/.zshrc` (`home/.zshrc` stowed to `~`) loads topic files in this order:

1. `path.zsh` files (modify PATH, MANPATH, etc.)
2. All other `.zsh` files (aliases, functions, settings)
3. `compinit`, then `completion.zsh` files

After topics are loaded:
- Window title hook is registered for terminal tabs
- Starship prompt starts up
- fzf key bindings and completions attach
- zoxide initializes directory tracking
- gh tab completions register
- History search bindings (up/down arrow) are set

## Customizing

### Adding private environment variables

Create `~/.localrc` — it's sourced by `.zshrc` but gitignored:

```sh
export MY_API_KEY="..."
export PATH="$HOME/my-tools:$PATH"
```

### Using a different git identity

Edit `~/.dotfiles/git/gitconfig.local.symlink` (gitignored):

```ini
[user]
        name = Your Name
        email = you@example.com
        signingkey = ~/.ssh/id_ed25519
```

### Adding a new tool

1. Create a topic directory: `mkdir mytool`
2. Add config files:
   - `mytool/path.zsh` — if it needs PATH changes
   - `mytool/aliases.zsh` — aliases
   - `mytool/completion.zsh` — completions
3. If the tool needs Homebrew: add it to `Brewfile`
4. If the tool needs a custom install: add `mytool/install.sh`

All `.zsh` files are auto-sourced. No manual registration needed.

### Updating symlinks after changes

```sh
cd ~/.dotfiles && stow -R home/
```

The `-R` flag restows and is safe to re-run (idempotent).

## Development

```sh
# Verify scripts are syntactically valid
bash -n script/bootstrap
bash -n macos/set-defaults.sh

# Validate starship config
STARSHIP_CONFIG=starship.toml starship print-config

# Dry-run stow to check for conflicts
cd ~/.dotfiles && stow -n -v home/
```

## Tech stack

| Component | Choice |
|-----------|--------|
| Shell | Zsh |
| Prompt | Starship |
| Editor | VS Code |
| Symlinks | GNU Stow |
| Packages | Homebrew |
| Git CLI | gh |
| Git signing | SSH (not GPG) |
| Search | ripgrep, fzf, fd |
| Navigation | zoxide |
