{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }: 
  flake-utils.lib.eachDefaultSystem (system: 
    let
      pkgs = import nixpkgs { inherit system; };
      lib = pkgs.lib;
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          xorg.libX11
          libGL
        ];

        LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs;[ xorg.libX11 libGL ]);
      };
    });
  }
