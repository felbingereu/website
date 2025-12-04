{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      defaultSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      eachDefaultSystem = lib.genAttrs defaultSystems;
    in
    {
      packages = eachDefaultSystem (
        system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
        in
        rec {
          felbinger-website = pkgs.callPackage ./package.nix { };
          default = felbinger-website;
        }
      );

      devShells = eachDefaultSystem (
        system:
        let
          pkgs = (import nixpkgs) {
            inherit system;
          };
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.felbinger-website ];
          };
        }
      );

      overlays.default = _: prev: {
        inherit (self.packages."${prev.system}") felbinger-website;
      };
    };
}
