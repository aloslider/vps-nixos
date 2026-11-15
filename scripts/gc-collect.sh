#!/usr/bin/env bash
set -euo pipefail

nix-collect-garbage -d

if [[ $(id -u) -ne 0 ]]; then
  sudo nix-collect-garbage -d
fi
