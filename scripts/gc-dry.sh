#!/usr/bin/env bash
set -euo pipefail

echo "User profiles:"
nix-collect-garbage --dry-run

if [[ $(id -u) -ne 0 ]]; then
  echo "System profiles:"
  sudo nix-collect-garbage --dry-run
fi
