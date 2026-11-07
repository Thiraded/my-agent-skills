#!/usr/bin/env bash
# Install skills into a project. Hosted skills are copied from this repo; "external" skills
# (see external.tsv) are fetched from their original author's GitHub repo at install time.
# usage: install.sh --list                 show hosted + external skills with links
#        install.sh --pick  [opts]         numbered menu: choose what to install
#        install.sh <name|category>... [--project DIR] [--prefix P] [--agents claude,codex] [--link]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SK="$HERE/skills"; EXT="$HERE/external.tsv"
project="$PWD"; prefix=""; agents="claude,codex"; link=0; pick=0; names=()
ext_rows() { grep -v '^#' "$EXT" | grep -v '^[[:space:]]*$' || true; }
show_list() {
  for c in "$SK"/*/; do echo "[$(basename "$c")]"; for s in "$c"*/; do echo "  $(basename "$s")"; done; done
  echo "[external - fetched from the author's GitHub]"
  ext_rows | while IFS=$'\t' read -r n r p; do printf '  %-30s https://github.com/%s/tree/HEAD/%s\n' "$n" "$r" "$p"; done
}
while [ $# -gt 0 ]; do
  case "$1" in
    --list) show_list; exit 0;;
    --pick) pick=1; shift;;
    --project) project="$2"; shift 2;;
    --prefix) prefix="$2"; shift 2;;
    --agents) agents="$2"; shift 2;;
    --link) link=1; shift;;
    -h|--help) sed -n 2,7p "$0"; exit 0;;
    *) names+=("$1"); shift;;
  esac
done
if [ $pick -eq 1 ]; then
  all=(); i=0
  for c in "$SK"/*/; do for s in "$c"*/; do all+=("$(basename "$s")"); i=$((i+1)); printf '%3d) %-30s (hosted)\n' $i "$(basename "$s")"; done; done
  while IFS=$'\t' read -r n r p; do all+=("$n"); i=$((i+1)); printf '%3d) %-30s (github.com/%s)\n' $i "$n" "$r"; done < <(ext_rows)
  read -r -p "numbers to install (e.g. 1 3 7-9, or 'all'): " sel
  [ "$sel" != "all" ] || sel="1-${#all[@]}"
  for t in $sel; do
    if [[ "$t" == *-* ]]; then for ((j=${t%-*}; j<=${t#*-}; j++)); do names+=("${all[$((j-1))]}"); done
    else names+=("${all[$((t-1))]}"); fi
  done
fi
[ ${#names[@]} -gt 0 ] || { echo "nothing to install (try --list or --pick)"; exit 1; }
[ -z "$prefix" ] || [ $link -eq 0 ] || { echo "--prefix cannot be combined with --link"; exit 1; }
[ -d "$project" ] || { echo "project dir not found: $project"; exit 1; }
CACHE="$(mktemp -d)"; trap 'rm -rf "$CACHE"' EXIT
fetch_ext() { # name -> prints local folder
  local row repo path dir; row="$(ext_rows | awk -F'\t' -v n="$1" '$1==n')"; [ -n "$row" ] || return 1
  repo="$(cut -f2 <<<"$row")"; path="$(cut -f3 <<<"$row")"; dir="$CACHE/${repo//\//_}"
  if [ ! -d "$dir" ]; then
    git clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" "$dir" >&2
  fi
  git -C "$dir" sparse-checkout add "$path" >&2
  echo "$dir/$path"
}
sources=()
for n in "${names[@]}"; do
  if [ -d "$SK/$n" ]; then
    for s in "$SK/$n"/*/; do sources+=("${s%/}"); done
  elif m=$(find "$SK" -mindepth 2 -maxdepth 2 -type d -name "$n" | head -1) && [ -n "$m" ]; then
    sources+=("$m")
  elif m=$(fetch_ext "$n"); then
    [ $link -eq 0 ] || { echo "external skills cannot use --link: $n"; exit 1; }
    sources+=("$m")
  else
    echo "not found: $n"; exit 1
  fi
done
IFS=, read -ra tg <<<"$agents"
for t in "${tg[@]}"; do
  case "$t" in
    claude) dest="$project/.claude/skills";;
    codex) dest="$project/.agents/skills";;
    *) echo "unknown agent: $t"; exit 1;;
  esac
  mkdir -p "$dest"
  for s in "${sources[@]}"; do
    n="$(basename "$s")"; out="$dest/$prefix$n"
    if [ -e "$out" ]; then echo "skip (exists): $out"; continue; fi
    if [ $link -eq 1 ]; then
      ln -s "$s" "$out"
    else
      cp -r "$s" "$out"
      [ -z "$prefix" ] || sed -i "0,/^name:.*/s//name: $prefix$n/" "$out/SKILL.md"
    fi
    echo "installed: $out"
  done
done
