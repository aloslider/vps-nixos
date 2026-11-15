{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    age
    bat
    btop
    curl
    git
    jq
    lazydocker
    lazygit
    openssl
    ripgrep
    sops
    tmux
    vim
    wget
  ];
}
