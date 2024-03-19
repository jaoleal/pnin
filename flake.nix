{
  description = "A NeoVim configuration with nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
  };
  outputs =
    { self
    , nixvim
    , flake-parts
    , ...
    } @ inputs:
    let
      lazy-nvim-config = import ./lazyconfig;
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./pre-commit-hooks.nix
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem =
        { pkgs
        , system
        , config
        , ...
        }:
        let
          nixvimLib = nixvim.lib.${system};

          nixvim' = nixvim.legacyPackages.${system};

          lazynvim = nixvim'.makeNixvimWithModule {
            inherit pkgs;
            module = lazy-nvim-config;
            extraSpecialArgs = { };
          };
        in
        {
          checks = {
            default = nixvimLib.check.mkTestDerivationFromNvim {
              nvim = lazynvim;
              name = "A nixvim configuration with lazy.nvim";
            };
          };
          packages = {
            default = lazynvim;
          };
          formatter = pkgs.nixpkgs-fmt;
          devShells = {
            default = pkgs.mkShell {
              buildInputs = [ lazynvim ];
              shellHook = ''
                ${config.pre-commit.installationScript}
              '';
            };
          };
        };

      flake.overlays.default = (final: prev: {
        lazynvim = self.packages.${final.system}.lazynvim;
      });
    };
}
