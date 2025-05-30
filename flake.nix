{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      ...
    }@inputs:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        ruby' = pkgs.ruby_3_4;
      in
      rec {
        formatter = pkgs.nixpkgs-fmt;
        devShells.default = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            formatter
            pkg-config
            ruby'
          ];
          buildInputs = with pkgs; [
            libyaml
          ];
          shellHook = # sh
            ''
              export MAKEFLAGS="-j$(nproc)" # make 'make' use all cores
              export MAKEOPTS="$MAKEFLAGS"
              export BUNDLE_FORCE_RUBY_PLATFORM=true # fix building gems with native extensions
            '';
        };
      }
    );
}
