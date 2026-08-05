# dotfiles — AI assistant guide

This repo manages shell and editor configuration using a topical directory
structure with GNU Stow for symlink management.

## Quick start

```sh
git clone https://github.com/kale-stew/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

## Structure

```
.
├── home/               # Stowed to ~/ via GNU Stow
│   ├── .zshrc          # -> ~/.zshrc (sources all topic .zsh files)
│   ├── .gitconfig      # -> ~/.gitconfig
├── git/
│   ├── ignore              # Linked to ~/.config/git/ignore by bootstrap
│   └── attributes          # Linked to ~/.config/git/attributes by bootstrap
├── bin/                # Scripts added to $PATH
├── git/                # Git configuration (aliases, completions, local template)
├── zsh/                # Zsh configuration (aliases, completion, config, window title)
├── vscode/             # VS Code settings, extensions, install script
├── macos/              # macOS defaults script
├── functions/          # Shell functions
├── node/               # NVM setup
├── osx/                # macOS-specific aliases
├── system/             # System-level shell config (PATH, env, keys, grc)
├── docker/             # Docker aliases
├── yarn/               # Yarn PATH setup
├── starship.toml       # Starship prompt config
├── Brewfile            # Homebrew packages
└── script/
    ├── bootstrap       # Entry point — installs deps, stows home/, runs brew bundle
    └── install         # Runs Brewfile and topic install.sh scripts
```

## Zsh loading order

`home/.zshrc` loads topic files in three phases:

1. All `path.zsh` files (modify $PATH)
2. All other `.zsh` files (aliases, functions, config)
3. Run `compinit`, then load all `completion.zsh` files

After sourcing all topics, it initializes:
- Window title precmd hook
- Starship prompt
- fzf key bindings
- zoxide directory jumper
- gh completion
- History search bindings (up/down arrow)

## Scripts

- **`git clean-stale`** (`bin/git-clean-stale`): sweeps stale local branches and
  their worktrees across one or more repos. **Dry-run by default** — nothing is
  deleted without `--execute`, so it is safe for humans and agents to run blindly.
  - Classifies branches: `gone` (upstream deleted), `merged`, `local-backup`,
    `unpushed`, `old`, `active`, `protected`. Auto-deletes `gone`/`merged`/
    `local-backup`; skips `unpushed`/`old` unless `--include-unpushed`/`--include-old`.
    Never touches integration branches, current HEAD, or kept worktrees.
  - Removes the worktree for any branch it deletes (dirty worktrees skipped
    unless `--force`).
  - Agent-friendly: `--json` for machine-readable output, `--yes` to skip prompts.
  - Repo list precedence: positional args → `--repos-file` → `$GIT_CLEAN_STALE_REPOS`
    → cwd. The repo set is user/host-specific and lives in `~/.localrc`
    (gitignored) as `$GIT_CLEAN_STALE_REPOS` — never hardcode repo paths here.
  - Examples: `git clean-stale` (dry-run all), `git clean-stale --json`,
    `git clean-stale --execute --yes`, `git clean-stale --include-old --days 90`.

## Conventions

- **Private config**: `~/.localrc` (shell env vars) and `~/.gitconfig.local`
  (git identity) — both are gitignored and must not be committed
- **Symlinks**: Run `stow -R home/` from the repo root after adding files
  to `home/`. The `-R` flag restows and is idempotent.
  Git XDG config files (`git/ignore`, `git/attributes`) are linked to
  `~/.config/git/` by bootstrap separately (not through stow).
- **New tools**: Add a topic directory with `.zsh` files (auto-sourced).
  If the tool needs `$PATH` changes, use `path.zsh`. If it needs
  completions, use `completion.zsh`. If it needs installation, add
  `install.sh` to the topic directory.
- **Brewfile**: Add new Homebrew formulas/casks here. Run `brew bundle`
  to install them.
- **Git**: All commits are signed via SSH (`gpg.format = ssh`). The git
  config includes `~/.gitconfig.local` for user identity overrides
  (symlinked from `git/gitconfig.local.symlink` by bootstrap).

## Tech stack

- **Shell**: Zsh (not bash, not fish)
- **Editor**: VS Code
- **Prompt**: Starship (config at starship.toml)
- **Package manager**: Homebrew
- **Symlink manager**: GNU Stow
- **Git**: SSH-signed commits, `gh` CLI (no hub)
- **Opencode skills**: Cloudflare platform skill installed globally
  (`~/.config/opencode/skills/cloudflare/`). Use `/cloudflare` to load it.

## Anti-patterns to avoid

- Don't add bash-specific syntax or configs (shell is Zsh)
- Don't modify `~/.gitconfig.local` or `~/.localrc` — they're user-private
- Don't commit secrets, tokens, or keys
- Don't change the symlink mechanism (stow) without updating this file
- Don't add files directly to ~/ — they'll be overwritten on next stow
- Don't add `.config/` to `home/` for stow — it conflicts with existing
  `~/.config` directories from other tools. Use bootstrap for these.

## Test

```sh
# Verify bootstrap syntax
bash -n script/bootstrap

# Verify macOS defaults don't error (macOS only)
bash -n macos/set-defaults.sh

# Validate starship config
STARSHIP_CONFIG=starship.toml starship print-config

# Dry-run stow to check for conflicts
cd ~/.dotfiles && stow -n -v home/
```
