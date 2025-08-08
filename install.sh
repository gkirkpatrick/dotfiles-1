#!/usr/bin/env sh
set -eu

DOTFILES_DIR="${DOTFILES_DIR:-$PWD}"
TARGET="${TARGET:-$HOME}"
BACKUP="${DOTFILES_BACKUP:-"$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"}"

mkdir -p "$BACKUP"

link() {
  src="$1"
  dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ] || [ ! -e "$dest" ]; then
    ln -snf "$src" "$dest"
  else
    echo "Backing up $dest -> $BACKUP"
    mv "$dest" "$BACKUP/"
    ln -snf "$src" "$dest"
  fi
}

IGNORE="install.sh README.markdown"

for path in "$DOTFILES_DIR"/*; do
  name=$(basename "$path")
  case " $IGNORE " in
    *" $name "*) continue ;;
  esac
  link "$path" "$TARGET/.$name"
done

echo "Done. Backups (if any) in $BACKUP"
