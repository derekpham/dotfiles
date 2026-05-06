#!/usr/bin/env bash
# Install dotfiles into $HOME by symlinking package contents.
#
# Each top-level directory is a "package" whose contents mirror $HOME.
# A directory named `<pkg>-linux` or `<pkg>-darwin` is a platform variant;
# asking for `<pkg>` resolves to the variant matching the current OS.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Linux)  OS=linux ;;
  Darwin) OS=darwin ;;
  *) echo "install.sh: unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

ALL=0
LIST=0
DRY=0
FORCE=0

usage() {
  cat <<'EOF'
Usage: install.sh [options] [pkg...]

Options:
  -a   install every package
  -l   list packages that resolve on this OS
  -n   dry run (print actions, change nothing)
  -f   no backup; remove conflicts and replace
  -h   show this help

Examples:
  install.sh bash zsh tmux
  install.sh -a
  install.sh -l
  install.sh -n claude
EOF
}

while getopts ":alnfh" opt; do
  case "$opt" in
    a) ALL=1 ;;
    l) LIST=1 ;;
    n) DRY=1 ;;
    f) FORCE=1 ;;
    h) usage; exit 0 ;;
    \?) echo "install.sh: unknown option -$OPTARG" >&2; usage >&2; exit 2 ;;
  esac
done
shift $((OPTIND - 1))

logical_name() {
  case "$1" in
    *-linux)  echo "${1%-linux}" ;;
    *-darwin) echo "${1%-darwin}" ;;
    *)        echo "$1" ;;
  esac
}

variant_suffix() {
  case "$1" in
    *-linux)  echo linux ;;
    *-darwin) echo darwin ;;
    *)        echo "" ;;
  esac
}

resolve_package() {
  local want=$1
  if [[ -d "$DOTFILES/$want-$OS" ]]; then
    echo "$want-$OS"
    return
  fi
  local sfx
  sfx=$(variant_suffix "$want")
  if [[ -n "$sfx" && "$sfx" != "$OS" ]]; then
    echo ""
    return
  fi
  if [[ -d "$DOTFILES/$want" ]]; then
    echo "$want"
    return
  fi
  echo ""
}

list_packages() {
  local dir base logical
  {
    for dir in "$DOTFILES"/*/; do
      [[ -d "$dir" ]] || continue
      base=$(basename "$dir")
      [[ "$base" == .* ]] && continue
      logical=$(logical_name "$base")
      if [[ -n "$(resolve_package "$logical")" ]]; then
        echo "$logical"
      fi
    done
  } | sort -u
}

log() { printf '%s\n' "$*"; }

link_one() {
  local src=$1 dst=$2
  if [[ -L "$dst" ]]; then
    local current
    current=$(readlink "$dst")
    if [[ "$current" == "$src" ]]; then
      log "skip   $dst"
      return
    fi
    if (( DRY )); then
      log "relink $dst -> $src (was -> $current)"
    else
      rm "$dst"
      ln -s "$src" "$dst"
      log "relink $dst -> $src"
    fi
    return
  fi
  if [[ -e "$dst" ]]; then
    if (( FORCE )); then
      if (( DRY )); then
        log "force  $dst -> $src (removing existing)"
      else
        rm -rf "$dst"
        ln -s "$src" "$dst"
        log "force  $dst -> $src"
      fi
    else
      local bak
      bak="$dst.bak.$(date +%Y%m%d%H%M%S)"
      if (( DRY )); then
        log "backup $dst -> $bak; link -> $src"
      else
        mv "$dst" "$bak"
        ln -s "$src" "$dst"
        log "backup $dst -> $bak; link -> $src"
      fi
    fi
    return
  fi
  if (( DRY )); then
    log "link   $dst -> $src"
  else
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    log "link   $dst -> $src"
  fi
}

install_dir() {
  local pkg_dir=$1 src rel dst
  while IFS= read -r -d '' src; do
    rel=${src#"$pkg_dir"/}
    dst="$HOME/$rel"
    link_one "$src" "$dst"
  done < <(find "$pkg_dir" -mindepth 1 -type f -print0)
}

install_package() {
  local name=$1 resolved sfx
  resolved=$(resolve_package "$name")
  if [[ -z "$resolved" ]]; then
    sfx=$(variant_suffix "$name")
    if [[ -n "$sfx" && "$sfx" != "$OS" ]]; then
      log "warn:  $name is $sfx-only; skipping on $OS"
      return
    fi
    echo "install.sh: unknown package: $name" >&2
    return 1
  fi
  if [[ "$resolved" != "$name" ]]; then
    log "=== $name ($resolved) ==="
  else
    log "=== $name ==="
  fi
  install_dir "$DOTFILES/$resolved"
}

if (( LIST )); then
  list_packages
  exit 0
fi

declare -a pkgs=()
if (( ALL )); then
  while IFS= read -r p; do pkgs+=("$p"); done < <(list_packages)
else
  pkgs=("$@")
fi

if [[ ${#pkgs[@]} -eq 0 ]]; then
  usage >&2
  exit 2
fi

for p in "${pkgs[@]}"; do
  install_package "$p"
done
