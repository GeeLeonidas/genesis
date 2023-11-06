{
  description = "Nim Template";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
  };

  outputs = { self, nixpkgs, ... }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forAllSystems ({ pkgs }: {
        default =
          let
            # Add executables
            executables = with pkgs; [
              clang
              mold
              gdb
              git
              nim
              nimPackages.nimble
            ];
            # Add libraries
            libraries = with pkgs; [
              # ...
            ];
          in
          pkgs.mkShell {
            # Bash statements that are executed by Nix shell
            shellHook = ''
              export CC="clang"
              export CXX="clang++"
              export LD_LIBRARY_PATH="${nixpkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH"
            '';

            packages = executables;
            buildInputs = libraries;
          };
      });
    };
}