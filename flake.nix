{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tcp-brutal = {
      url = "github:HyNetworks/tcp-brutal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      tcp-brutal,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs;
      customLib = pkgs.lib.extend (
        self: super: {
          custom = (
            import ./lib {
              inherit (pkgs) lib;
            }
          );
        }
      );
    in
    {
      nixosConfigurations = {
        f1-msk-node = pkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit (inputs) disko;
            lib = customLib;
          };
          modules = [
            ./hosts/f1-msk-node/configuration.nix
            tcp-brutal.nixosModules.default
          ];
        };
        im-che-node = pkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit (inputs) disko;
            lib = customLib;
          };
          modules = [
            ./hosts/im-che-node/configuration.nix
            tcp-brutal.nixosModules.default
          ];
        };
        im-che-panel = pkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit (inputs) disko;
            lib = customLib;
          };
          modules = [
            ./hosts/im-che-panel/configuration.nix
          ];
        };
        ve-swe-node = pkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs;
            inherit (inputs) disko;
            lib = customLib;
          };
          modules = [
            ./hosts/ve-swe-node/configuration.nix
            tcp-brutal.nixosModules.default
          ];
        };
      };

      devShells.${system}.default = import ./shell {
        inherit nixpkgs system;
      };
    };
}
