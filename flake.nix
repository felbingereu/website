{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = { self, nixpkgs }: let
    inherit (nixpkgs) lib;
    defaultSystems = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-linux"
      "aarch64-darwin"
    ];
    eachDefaultSystem = lib.genAttrs defaultSystems;
  in {
    devShells = eachDefaultSystem (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = pkgs.mkShell {
        shellHook = ''
          source ./venv/bin/activate
        '';
      };
    });
  };
}
