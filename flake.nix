rec {
  description = "Daemon for receiving notifications from Home Assistant and displaying them using libnotify.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { moduleWithSystem, ... }:
      let
        pname = "ha-notifier";
        version = "0.1.2";
      in
      {
        debug = true;

        perSystem =
          { pkgs, ... }:
          (
            let
              beam-pkg = pkgs.beam.packagesWith pkgs.erlang_26;
              elixir = beam-pkg.elixir_1_17;
              mixRelease = beam-pkg.mixRelease.override { inherit elixir; };
              elixir-ls = pkgs.elixir-ls.override { inherit elixir mixRelease; };
            in
            {
              devShells.default = pkgs.mkShell {
                buildInputs = [
                  elixir
                  elixir-ls
                ];

                shellHook = ''
                  echo "$(elixir --version | tr -s '\n')"
                  echo ""
                  echo "LFG."
                '';
              };

              packages.default = mixRelease (
                let
                  src = ./.;

                  mixFodDeps = beam-pkg.fetchMixDeps {
                    pname = "mix-deps-${pname}";
                    inherit src version;
                    hash = "sha256-sMLIHpXEirMNiYJwLUvRv5ZJkPYJDwz6QFMGMiYDHro=";
                  };
                in
                {
                  inherit
                    src
                    pname
                    version
                    mixFodDeps
                    ;
                }
              );
            }
          );

        flake = {
          homeManagerModules.default = moduleWithSystem (
            { pkgs, self' }:
            { config, lib, ... }:
            let
              cfg = config.services.${pname};
            in
            {
              options.services.${pname} = {
                enable = lib.mkEnableOption pname;
                port = lib.mkOption {
                  type = lib.types.port;
                  default = 8124;
                  description = "Port to listen for Home Assistant via the REST integration.";
                };
                libnotify = lib.mkOption {
                  type = lib.types.package;
                  default = pkgs.libnotify;
                  description = "libnotify package to use";
                };
                alsa-utils = lib.mkOption {
                  type = lib.types.package;
                  default = pkgs.alsa-utils;
                  description = "alsa-utils package to use";
                };
              };

              config = lib.mkIf cfg.enable {
                systemd.user.services.${pname} = {
                  Unit.Description = description;
                  Install.WantedBy = [ "graphical-session.target" ];
                  Service = {
                    ExecStart = "${pkgs.writeShellScript "ha-notifier" ''
                      export RELEASE_DISTRIBUTION=none
                      export RELEASE_COOKIE=$(${pkgs.coreutils}/bin/tr -dc A-Za-z0-9 < /dev/urandom | ${pkgs.coreutils}/bin/head -c 20)
                      export PORT=${toString cfg.port}
                      export NOTIFY_SEND=${"${cfg.libnotify}/bin/notify-send"}
                      export APLAY=${"${cfg.alsa-utils}/bin/aplay"}
                      ${self'.packages.default}/bin/ha_notifier start
                    ''}";
                    Restart = "on-failure";
                    RestartSec = "5";
                  };
                };
              };
            }
          );
        };

        systems = [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
          "x86_64-darwin"
        ];
      }
    );
}
