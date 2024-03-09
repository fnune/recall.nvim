{
  description = "A development shell for Recall";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShell = pkgs.mkShell {
        buildInputs = with pkgs; [
          pre-commit
          stylua
          nodePackages.prettier
          luajitPackages.luacheck
        ];
      };
    });
}
