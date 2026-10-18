#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
hooks_dir="$(git -C "$repo_root" rev-parse --git-path hooks)"

if [[ "$hooks_dir" != /* ]]; then
  hooks_dir="$repo_root/$hooks_dir"
fi

mkdir -p -- "$hooks_dir"
cp -- "$script_dir/pre-commit" "$hooks_dir/pre-commit"
chmod +x "$hooks_dir/pre-commit"

printf 'Installed pre-commit hook at %s\n' "$hooks_dir/pre-commit"
