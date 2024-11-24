rec {
  description = "Daemon for receiving notifications from Home Assistant and displaying them using libnotify.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pname = "ha-notifier";
        version = "0.1.0";
        pkgs = import nixpkgs { inherit system; };
        beam-pkg = pkgs.beam.packagesWith pkgs.erlang_26;
        elixir = beam-pkg.elixir_1_17;
        mixRelease = beam-pkg.mixRelease.override { inherit elixir; };
        elixir-ls = pkgs.elixir-ls.override { inherit elixir mixRelease; };
      in
      rec {
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
              hash = "sha256-qjj1ZAGP4+QXbQTeXYb5IU8Xlhqt9WXsuWuwgCT1Hsk=";
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

        homeManagerModules.default =
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
            };

            config = lib.mkIf cfg.enable {
              systemd.services.${pname} = {
                inherit description;
                wantedBy = [ "multi-user.target" ];
                script = ''
                  export RELEASE_COOKIE=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
                  ${packages.default}/bin/ha_notifier start
                '';
                environment = {
                  RELEASE_DISTRIBUTION = "none";
                  PORT = toString cfg.port;
                };
              };
            };
          };
      }
    );
}
