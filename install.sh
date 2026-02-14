#!/usr/bin/env sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
TARGET="${TARGET:-$HOME}"
BACKUP="${DOTFILES_BACKUP:-"$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"}"

# BSD ln on macOS behaves slightly differently than GNU ln. Handle it here.
LN_OPTS="-snf"
if [ "$(uname)" = "Darwin" ]; then
  LN_OPTS="-sfn"
fi

mkdir -p "$BACKUP"

link() {
  src="$1"
  dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] || [ ! -e "$dest" ]; then
    ln $LN_OPTS "$src" "$dest"
  else
    echo "Backing up $dest -> $BACKUP"
    mv "$dest" "$BACKUP/"
    ln $LN_OPTS "$src" "$dest"
  fi
}

IGNORE="install.sh README.markdown claude"

for path in "$DOTFILES_DIR"/*; do
  name=$(basename "$path")
  case " $IGNORE " in
    *" $name "*) continue ;;
  esac
  link "$path" "$TARGET/.$name"
done

# Install Claude Code config files into ~/.claude/
if [ -d "$DOTFILES_DIR/claude" ]; then
  mkdir -p "$TARGET/.claude"
  for path in "$DOTFILES_DIR/claude"/*; do
    name=$(basename "$path")
    link "$path" "$TARGET/.claude/$name"
  done
fi

echo "Done. Backups (if any) in $BACKUP"
