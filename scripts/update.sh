#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
source "$root/scripts/select-node.sh"

if [[ $# -ge 1 ]]; then
  node=$1
else
  node=$(select_node)
fi

nix run nixpkgs#nixos-rebuild -- switch \
  --flake ".#$node" \
  --target-host "$node" \
  --sudo \
  --ask-elevate-password
