{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    purs-nix.url = "github:purs-nix/purs-nix";
    utils.url = "github:ursi/flake-utils";
    ps-tools.follows = "purs-nix/ps-tools";
    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;
  };

  outputs = { self, utils, ... }@inputs:
    let
      # TODO add missing arm to match standard systems
      #  right now purs-nix is only compatible with x86_64-linux
      systems = [ "x86_64-linux" ];
      make-pkgs = system: import inputs.nixpkgs {
        inherit system;
        # required by npmlock2nix
        config.permittedInsecurePackages = [
          "nodejs-16.20.1"
        ];
      };
    in
    utils.apply-systems
      { inherit inputs systems make-pkgs; }
      ({ system, pkgs, ps-tools, ... }:
        let
          npmlock2nix = import inputs.npmlock2nix { inherit pkgs; };
          purs-nix = inputs.purs-nix { inherit system; };
          node_modules = npmlock2nix.v2.node_modules { src = ./.; } + /node_modules;
          ps = purs-nix.purs
            {
              # Project dir (src, test)
              dir = ./.;
              # Dependencies
              dependencies =
                with purs-nix.ps-pkgs;
                [
                  prelude
                  effect
                  aff
                ];
              # FFI dependencies
              foreign."Temporal.Client" = { inherit node_modules; };
              foreign."Temporal.Client.Connection" = { inherit node_modules; };
            };
          ps-command = ps.command { };

        in
        {
          apps.default =
            {
              type = "app";
              program = "${self.packages.${system}.default}";
            };

          packages =
            with ps;
            {
              default = pkgs.writeScript "evo-siigo" ''
                #!${pkgs.nodejs}/bin/node
                import("${self.packages.${system}.output}/Main/index.js").then(m=>m.main())
              '';

              output = output { };
            };

          devShells.default = pkgs.mkShell {
            packages =
              with pkgs;
              [
                ps-command
                # optional devShell tools
                ps-tools.for-0_15.purescript-language-server
                ps-tools.for-0_15.purty
                nodejs
              ];
          };
        });

  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    extra-experimental-features = "nix-command flakes";
    # This sets the flake to use nix cache.
    # Nix should ask for permission before using it,
    # but remove it here if you do not want it to.
    extra-substituters = [
      "https://klarkc.cachix.org?priority=99"
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "klarkc.cachix.org-1:R+z+m4Cq0hMgfZ7AQ42WRpGuHJumLLx3k0XhwpNFq9U="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
}
