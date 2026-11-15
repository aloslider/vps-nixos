{
  nixpkgs,
  system,
}:
let
  pkgSet = import nixpkgs { inherit system; };
  toolPath = pkgSet.lib.makeBinPath (
    with pkgSet;
    [
      age
      coreutils
      nix
      sops
    ]
  );
  command =
    name: text:
    pkgSet.writeShellScriptBin name ''
      set -euo pipefail

      export PATH="${toolPath}:$PATH"

      if [[ ! -f flake.nix ]]; then
        echo "Run this from the vps-nixos checkout." >&2
        exit 1
      fi

      ${text}
    '';
  selectNode = ''
    select_node() {
      local raw choice
      local -a hosts

      raw=$(
        nix eval --raw .#nixosConfigurations \
          --apply 'cfgs: builtins.concatStringsSep "\n" (builtins.sort builtins.lessThan (builtins.attrNames cfgs))'
      )
      mapfile -t hosts <<< "$raw"

      if (( ''${#hosts[@]} == 0 )) || [[ -z ''${hosts[0]} ]]; then
        echo "No nixosConfigurations in this flake." >&2
        return 1
      fi

      local i=1
      for node in "''${hosts[@]}"; do
        printf '%d) %s\n' "$i" "$node" >&2
        i=$((i + 1))
      done

      read -r -p "Host number: " choice
      if [[ ! $choice =~ ^[0-9]+$ ]]; then
        echo "Not a number: ''${choice}" >&2
        return 1
      fi

      if ((10#$choice < 1 || 10#$choice > ''${#hosts[@]})); then
        echo "Out of range: ''${choice}" >&2
        return 1
      fi

      printf '%s\n' "''${hosts[10#$choice - 1]}"
    }
  '';
in
pkgSet.mkShell {
  packages = builtins.attrValues {
    install = command "install" ''
      ${selectNode}
      if [[ $# -ge 1 ]]; then
        host=$1
      else
        host=$(select_node)
      fi

      age_key="''${VPS_AGE_KEY:-$HOME/.config/sops/age/$host-key.txt}"
      extra_dir=$(mktemp -d)
      trap 'rm -rf "$extra_dir"' EXIT

      install -d -m 0700 "$extra_dir/etc/age"
      install -m 0600 "$age_key" "$extra_dir/etc/age/key.txt"

      read -rp "Remote user: " user

      nix run github:nix-community/nixos-anywhere -- \
        --no-disko-deps \
        --flake ".#$host" \
        --target-host "$user@$host" \
        --extra-files "$extra_dir"
    '';
    update = command "update" ''
      ${selectNode}
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
    '';
    edit-secrets = command "edit-secrets" ''
      ${selectNode}
      if [[ $# -ge 1 ]]; then
        node=$1
      else
        node=$(select_node)
      fi

      SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/$node-key.txt" \
        sops --config .sops.yaml "hosts/$node/secrets.yaml"
    '';
    gc-dry = command "gc-dry" ''
      dead=$(mktemp)
      trap 'rm -f "$dead"' EXIT
      nix-store --gc --print-dead > "$dead"
      count=$(wc -l < "$dead")
      if [[ $count -eq 0 ]]; then
        echo "0 paths, 0"
        exit 0
      fi
      size=$(tr '\n' '\0' < "$dead" | du -hc --files0-from=- | awk '$2 == "total" { print $1 }')
      echo "$count paths, $size"
    '';
    gc-collect = command "gc-collect" ''
      nix-collect-garbage -d

      if [[ $(id -u) -ne 0 ]]; then
        sudo nix-collect-garbage -d
      fi
    '';
  };
}
