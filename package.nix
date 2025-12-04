{
  lib,
  stdenv,
  python3Packages,
}:
let
  inherit (python3Packages) mkdocs mkdocs-material mkdocs-redirects;
in
stdenv.mkDerivation {
  pname = "felbinger-website";
  version = "1.0.0";

  src = ./.;

  buildInputs = [
    mkdocs
    mkdocs-material
    mkdocs-redirects
  ];

  buildPhase = ''
    mkdir -p $out
    mkdocs build -d $out/
  '';

  # no need to build on remote builder
  preferLocalBuild = true;

  meta = {
    description = "HTML rendered page of felbinger.eu website";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ felbinger ];
  };
}
