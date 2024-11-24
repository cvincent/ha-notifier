rec {
  description = "Daemon for receiving notifications from Home Assistant and displaying them using libnotify.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        pname = "ha-notifier";
        version = "0.1.0";
      in
      {
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
            }
          );

        flake =
          { self, ... }:
          {
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
                  systemd.user.services.${pname} = {
                    Unit.Description = description;
                    Install.WantedBy = [ "multi-user.target" ];
                    Service.ExecStart = "${self.pkgs.writeShellScript "ha-notifier" ''
                      #!/run/current-system/sw/bin/bash
                      export RELEASE_DISTRIBUTION=none
                      export RELEASE_COOKIE=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 20)
                      export PORT=${toString cfg.port}
                      ${self.packages.default}/bin/ha_notifier start
                    ''}";
                  };
                };
              };
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
