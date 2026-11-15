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

SOPS_AGE_KEY_FILE=~/.config/sops/age/$node-key.txt \
  sops --config ~/Projects/vps-nixos/.sops.yaml \
  ~/Projects/vps-nixos/hosts/$node/secrets.yaml
