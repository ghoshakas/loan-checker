#!/usr/bin/env bash
# Pull the latest commits from the upstream backend/frontend repos into this
# monorepo's submodules, then show what changed.
#
#   scripts/pull-upstream.sh             # both
#   scripts/pull-upstream.sh backend     # just one
#
# Afterwards, commit the updated submodule pointers so everyone who clones
# the monorepo gets the same versions:
#   git add backend frontend && git commit -m "Bump backend/frontend"
set -euo pipefail

cd "$(dirname "$0")/.."

modules=("$@")
[ ${#modules[@]} -eq 0 ] && modules=(backend frontend)

for m in "${modules[@]}"; do
  case "$m" in backend|frontend) ;; *) echo "Unknown module: $m (use backend or frontend)" >&2; exit 1 ;; esac
done

# Make sure the submodules are checked out (fresh clone without --recursive).
git submodule update --init -- "${modules[@]}"

for m in "${modules[@]}"; do
  before=$(git -C "$m" rev-parse HEAD)
  branch=$(git config -f .gitmodules --get "submodule.$m.branch" || echo main)

  if [ -n "$(git -C "$m" status --porcelain --untracked-files=no)" ]; then
    echo "!! $m has uncommitted changes; commit or stash them first." >&2
    exit 1
  fi

  echo "==> $m: pulling origin/$branch"
  git submodule update --remote --merge -- "$m"

  after=$(git -C "$m" rev-parse HEAD)
  if [ "$before" = "$after" ]; then
    echo "    already up to date ($(git -C "$m" rev-parse --short HEAD))"
  else
    git -C "$m" log --oneline "$before..$after" | sed 's/^/    /'
  fi
done

echo
git submodule status -- "${modules[@]}"
if ! git diff --quiet -- "${modules[@]}"; then
  echo
  echo "Submodule pointers moved. Rebuild and commit them:"
  echo "  docker compose up -d --build"
  echo "  git add ${modules[*]} && git commit -m \"Bump ${modules[*]}\""
fi
