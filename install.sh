#!/usr/bin/env bash
# Install skills from this library into a project.
# usage: install.sh --list
#        install.sh <name|category>... [--project DIR] [--prefix P] [--agents claude,codex] [--link]
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SK="$HERE/skills"
project="$PWD"; prefix=""; agents="claude,codex"; link=0; names=()
while [ $# -gt 0 ]; do
  case "$1" in
    --list) for c in "$SK"/*/; do echo "[$(basename "$c")]"; for s in "$c"*/; do echo "  $(basename "$s")"; done; done; exit 0;;
    --project) project="$2"; shift 2;;
    --prefix) prefix="$2"; shift 2;;
    --agents) agents="$2"; shift 2;;
    --link) link=1; shift;;
    -h|--help) sed -n 2,5p "$0"; exit 0;;
    *) names+=("$1"); shift;;
  esac
done
[ ${#names[@]} -gt 0 ] || { echo "nothing to install (try --list)"; exit 1; }
[ -z "$prefix" ] || [ $link -eq 0 ] || { echo "--prefix cannot be combined with --link"; exit 1; }
[ -d "$project" ] || { echo "project dir not found: $project"; exit 1; }
sources=()
for n in "${names[@]}"; do
  if [ -d "$SK/$n" ]; then
    for s in "$SK/$n"/*/; do sources+=("${s%/}"); done
  else
    m=$(find "$SK" -mindepth 2 -maxdepth 2 -type d -name "$n" | head -1)
    [ -n "$m" ] || { echo "not found: $n"; exit 1; }
    sources+=("$m")
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
