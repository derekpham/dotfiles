#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

old_skill_dir="$test_home/.agents/skills/pr-create"
mkdir -p "$old_skill_dir"
ln -s "$repo_root/codex/.agents/skills/pr-create/SKILL.md" "$old_skill_dir/SKILL.md"

HOME="$test_home" "$repo_root/install.sh" codex >/dev/null

for skill in pr-create pr-review ship; do
  target="$repo_root/codex/.agents/skills/$skill"
  installed="$test_home/.agents/skills/$skill"
  [[ -L "$installed" ]]
  [[ "$(readlink "$installed")" == "$target" ]]
  [[ ! -L "$installed/SKILL.md" ]]
done

[[ -L "$test_home/.codex/AGENTS.md" ]]
