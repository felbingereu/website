{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    disko.url = "github:nix-community/disko";
    sops-nix.url = "github:Mic92/sops-nix";
  };
  outputs = { nixpkgs, disko, sops-nix, ... }: {
    nixosConfigurations = {
      notes = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/notes/configuration.nix
          ./hosts/notes/hardware-configuration.nix
          disko.nixosModules.disko
          ./hosts/notes/disk-config.nix
          sops-nix.nixosModules.default
          ./modules/hedgedoc.nix
          ./modules/hardening.nix
        ];
      };
      auth = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/auth/configuration.nix
          ./hosts/auth/hardware-configuration.nix
          disko.nixosModules.disko
          ./hosts/auth/disk-config.nix
          sops-nix.nixosModules.default
          ./modules/keycloak.nix
          ./modules/hardening.nix
        ];
      };
    };
  };
}
