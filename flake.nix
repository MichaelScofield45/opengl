{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }: 
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    lib = pkgs.lib;
  in
  {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        xorg.libX11
        libGL
      ];

      LD_LIBRARY_PATH = lib.makeLibraryPath (with pkgs;[ xorg.libX11 libGL ]);
    };
  };
}
