#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
source "$root/scripts/select-node.sh"

if [[ $# -ge 1 ]]; then
  host=$1
else
  host=$(select_node)
fi

age_key="${VPS_AGE_KEY:-$HOME/.config/sops/age/$host-key.txt}"
extra_dir=$(mktemp -d)
trap 'rm -rf "$extra_dir"' EXIT

read -rp "Remote user: " user

install -d -m 0700 "$extra_dir/etc/age"
install -m 0600 "$age_key" "$extra_dir/etc/age/key.txt"

nix run github:nix-community/nixos-anywhere -- \
  --no-disko-deps \
  --flake ".#$host" \
  --target-host "$user@$host" \
  --extra-files "$extra_dir"
