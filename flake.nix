{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    purs-nix.url = "github:purs-nix/purs-nix";
    utils.url = "github:ursi/flake-utils";
    ps-tools.follows = "purs-nix/ps-tools";
    npmlock2nix.url = "github:nix-community/npmlock2nix";
    npmlock2nix.flake = false;
    simple-csv.url = "github:smartermaths/purescript-simple-csv";
    simple-csv.flake = false;
    generators.url = "github:nix-community/nixos-generators";
    generators.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, utils, ... }@inputs:
    let
      linux = "linux";
      x64 = "x86_64";
      linux-x64 = "${x64}-${linux}";
      # TODO add missing arm to match standard systems
      #  right now purs-nix is only compatible with x86_64-linux
      platform = x64;
      os = linux;
      systems = [ "${platform}-${os}" ];
      make-pkgs = system: import inputs.nixpkgs {
        inherit system;
        # required by npmlock2nix
        config.permittedInsecurePackages = [
          "nodejs-16.20.1"
        ];
      };
      nixosModules =
        let
          inherit (inputs.nixpkgs.lib) types mkDefault;
          inherit (inputs.generators.nixosModules) all-formats;
          logger = { lib, ... }: {
            options.services.logger.enable =
              lib.mkEnableOption "logger";
            config.systemd.services.logger = {
              description = "Monitor systemd journal in real-time";
              wantedBy = [ "multi-user.target" ];
              script = "journalctl -b -f";
              serviceConfig = {
                StandardOutput = "tty";
                StandardError = "tty";
                TTYPath = "/dev/console";
                Restart = "always";
              };
            };
          };
          temporal = { lib, pkgs, config, ... }:
            let
              inherit (lib) mkIf mkEnableOption;
              cfg = config.services.temporal;
              user = "temporal";
              group = "temporal";
            in
            {
              options.services.temporal = {
                enable = mkEnableOption "temporal";
              };
              config = {
                environment.defaultPackages = with pkgs; [
                  temporalite
                ];
                users = {
                  users.${user} = {
                    inherit group;
                    isSystemUser = true;
                    description = "Temporalite Daemon";
                    home = "/var/temporal";
                    createHome = true;
                  };
                  groups.${group} = { };
                };
                systemd.services.temporal = {
                  description = "Temporalite server";
                  wantedBy = [ "multi-user.target" ];
                  path = with pkgs; [ temporalite ];
                  script = "temporalite start --namespace default";
                  startLimitIntervalSec = 60;
                  startLimitBurst = 3;
                  serviceConfig = {
                    User = user;
                    Group = group;
                    WorkingDirectory = "~";
                  };
                };
              };
            };
          evo-siigo = { config, lib, ... }: {
            options.services.evo-siigo.enable =
              lib.mkEnableOption "evo-siigo";

            config.systemd.services.evo-siigo = {
              description = "Evo-siigo worker";
              wantedBy = [ "multi-user.target" ];
              requires = [ "temporal.service" ];
              script = self.apps.${linux-x64}.default.program;
              startLimitIntervalSec = 60;
              startLimitBurst = 3;
              serviceConfig.DynamicUser = "yes";
            };
          };
          worker = { config, ... }: rec {
            imports = [
              all-formats
              temporal
              evo-siigo
            ];
            system.stateVersion = config.system.nixos.version;
            fileSystems."/".device = "none";
            boot.loader.grub.device = "nodev";
            security.sudo.wheelNeedsPassword = false;
            programs.vim.defaultEditor = true;
            users = {
              users.klarkc = {
                isNormalUser = true;
                home = "/home/klarkc";
                extraGroups = [ "wheel" ];
                openssh.authorizedKeys.keys = [
                  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFYlM/N+ZY5j5ddzyWWoEsYwnhhDiTGlmprZscFapgWt"
                ];
              };
              mutableUsers = false;
            };
            services.openssh.enable = true;
            networking.firewall.enable = false;
            formatConfigs.vm-nogui = {
              imports = imports ++ [ logger ];
              services.logger.enable = true;
              virtualisation.forwardPorts = [
                { from = "host"; host.port = 2222; guest.port = 22; }
                { from = "host"; host.port = 8233; guest.port = 8233; }
                { from = "host"; host.port = 8080; guest.port = 8080; }
              ];
            };
          };
        in
        { inherit evo-siigo temporal logger worker; };

      nixosConfigurations =
        let
          inherit (inputs.nixpkgs.lib) nixosSystem;
          inherit (self.nixosModules) worker;
        in
        {
          evo-siigo-srv0 = nixosSystem {
            system = linux-x64;
            modules = [
              worker
              ({
                networking.hostName = "evo-siigo-srv0";
              })
            ];
          };
        };
    in
    { inherit nixosModules nixosConfigurations; } // utils.apply-systems
      { inherit inputs systems make-pkgs; }
      ({ system, pkgs, ps-tools, ... }:
        let
          inherit (pkgs) nodejs;
          inherit (ps-tools.for-0_15) purescript purs-tidy purescript-language-server;
          npmlock2nix = import inputs.npmlock2nix { inherit pkgs; };
          purs-nix = inputs.purs-nix { inherit system; };
          node_modules = npmlock2nix.v2.node_modules { src = ./.; inherit nodejs; } + /node_modules;
          ulid_ = pkgs.lib.recursiveUpdate purs-nix.ps-pkgs.ulid {
            purs-nix-info.foreign.Ulid = { inherit node_modules; };
          };
          simple-csv_ = purs-nix.build {
            name = "simple-csv";
            src.path = inputs.simple-csv;
            info.dependencies = with purs-nix.ps-pkgs; [
              arrays
              "assert"
              control
              effect
              either
              maybe
              prelude
              string-parsers
              strings
            ];
          };
          ps = purs-nix.purs
            {
              # Project dir (src, test)
              dir = ./.;
              # Dependencies
              dependencies =
                with purs-nix.ps-pkgs;
                [
                  debug
                  prelude
                  stringutils
                  console
                  effect
                  aff
                  js-promise
                  js-promise-aff
                  unlift
                  ulid_
                  foreign
                  foreign-object
                  parallel
                  node-path
                  httpurple
                  httpurple-argonaut
                  argonaut
                  fetch
                  fetch-argonaut
                  newtype
                  node-process
                  node-buffer
                  dotenv
                  monad-logger
                  record
                  free
                  formatters
                  simple-csv_
                ];
              # FFI dependencies
              foreign."Temporal.Client" = { inherit node_modules; };
              foreign."Temporal.Client.Connection" = { inherit node_modules; };
              foreign."Temporal.Node.Worker" = { inherit node_modules; };
              foreign."Temporal.Workflow" = { inherit node_modules; };
              # compiler
              inherit purescript nodejs;
            };
          ps-command = ps.command { };
          purs-watch = pkgs.writeShellApplication {
            name = "purs-watch";
            runtimeInputs = with pkgs; [ entr ps-command ];
            text = ''find src | entr -s "purs-nix $*"'';
          };
          concurrent = pkgs.writeShellApplication {
            name = "concurrent";
            runtimeInputs = with pkgs; [
              concurrently
            ];
            text = ''
              concurrently\
                --color "auto"\
                --prefix "[{command}]"\
                --handle-input\
                --restart-tries 10\
                "$@"
            '';
          };
          devRuntimeInputs = with pkgs; [
            purs-watch
            concurrent
            temporalite
          ];
          dev = pkgs.writeShellApplication {
            name = "dev";
            runtimeInputs = devRuntimeInputs;
            text = ''concurrent \
              "purs-watch run"\
              "temporalite start --namespace default"
            '';
          };
          dev-debug = pkgs.writeShellApplication {
            name = "dev-debug";
            runtimeInputs = devRuntimeInputs ++ [ ps-command ];
            text = ''concurrent \
              "TEMPORAL_DEBUG=1 NODE_OPTIONS=--inspect-brk purs-nix run"\
              "temporalite start --namespace default"
            '';
          };
          vm = name: pkgs.writeShellApplication {
            inherit name;
            text = ''
              export USE_TMPDIR=0
              ${self.nixosConfigurations.${name}.config.formats.vm-nogui}
            '';
          };
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
              devRuntimeInputs
              ++ [
                ps-command
                dev
                dev-debug
                (vm "evo-siigo-srv0")
                purescript
                purs-tidy
                purescript-language-server
                pkgs.nodejs
              ];
            shellHook = ''
              alias log_='printf "\033[1;32m%s\033[0m\n" "$@"'
              alias info_='printf "\033[1;34m[INFO] %s\033[0m\n" "$@"'
              log_ "Welcome to evo-siigo shell."
              info_ "Available commands: dev, dev-debug, evo-siigo-srv0."
            '';
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
