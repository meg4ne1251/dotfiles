# dotfiles

Personal dotfiles for Linux (Debian/Ubuntu). One command symlinks everything
into your home directory, installs a baseline of apt packages, and sets up a few
helper scripts.

## Install

```bash
git clone https://github.com/meg4ne1251/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

### Options

| Flag            | Effect                                              |
| --------------- | --------------------------------------------------- |
| `--no-packages` | Skip the apt package installation step              |
| `--dry-run`     | Show what would happen without changing anything    |
| `-h`, `--help`  | Show usage                                          |

What `install.sh` does:

1. Symlinks every file under `home/` into `~/` (nested paths supported).
2. Backs up any existing real file to `~/.dotfiles-backup/<timestamp>/` first.
3. Installs the packages listed in `packages.txt` via `apt` (needs sudo).
4. Copies `bin/` into `~/bin/` and marks the scripts executable.

Logs are colour-coded: `[INFO]` `[ OK ]` `[WARN]` `[ERR ]`.

## Layout

```
dotfiles/
├── install.sh          # installer
├── packages.txt        # apt packages
├── home/               # everything here is symlinked into ~/
│   ├── .bashrc
│   ├── .bash_profile
│   ├── .gitconfig
│   ├── .vimrc
│   ├── .inputrc
│   ├── .tmux.conf
│   ├── .gitconfig.local.example
│   └── .bashrc.local.example
└── bin/                # copied into ~/bin/
    └── extract
```

## Machine-specific & secret config

Two files are git-ignored so machine-specific and private settings stay out of
the repo:

- **`~/.gitconfig.local`** — your git name and email (included by `~/.gitconfig`).
- **`~/.bashrc.local`** — per-machine env vars / aliases (sourced by `~/.bashrc`).

After installing, set up your git identity:

```bash
cp ~/.gitconfig.local.example ~/.gitconfig.local
$EDITOR ~/.gitconfig.local
```

## Highlights

- **bash** — 10k de-duplicated, timestamped history; git branch in the prompt;
  `bat`/`fdfind` auto-aliased when present; helpers like `mkcd`, `cdl`, `serve`,
  `port`, `bak`, `psg`.
- **git** — sensible defaults (`push.autoSetupRemote`, `fetch.prune`,
  `rebase.autosquash`, `diff3` conflicts, histogram diffs) and short aliases.
- **vim** — Japanese encoding auto-detection, persistent undo, `jj` to escape,
  Space leader mappings, trailing-whitespace stripping on save.
- **tmux** — `Ctrl+g` prefix, mouse + true color, 50k scrollback, intuitive
  splits/navigation, vi copy mode.
- **readline** — prefix history search on arrows, case-insensitive completion.
