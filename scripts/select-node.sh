select_node() {
  local raw choice
  local -a hosts

  raw=$(
    nix eval --raw .#nixosConfigurations \
      --apply 'cfgs: builtins.concatStringsSep "\n" (builtins.sort builtins.lessThan (builtins.attrNames cfgs))'
  )

  mapfile -t hosts <<< "$raw"
  if ((${#hosts[@]} == 0)) || [[ -z ${hosts[0]} ]]; then
    echo "No nixosConfigurations in this flake." >&2
    return 1
  fi

  local i=1
  for node in "${hosts[@]}"; do
    printf '%d) %s\n' "$i" "$node" >&2
    i=$((i + 1))
  done

  read -r -p "Host number: " choice
  if [[ ! $choice =~ ^[0-9]+$ ]]; then
    echo "Not a number: ${choice}" >&2
    return 1
  fi
  if ((10#$choice < 1 || 10#$choice > ${#hosts[@]})); then
    echo "Out of range: ${choice}" >&2
    return 1
  fi

  printf '%s\n' "${hosts[10#$choice - 1]}"
}
