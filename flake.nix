{
  description = "Daemon for receiving notifications from Home Assistant and displaying them using libnotify.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      # pname = "ha-notifier";
      # version = "0.1.0";

      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      beam-pkg = pkgs.beam.packagesWith pkgs.erlang_26;
      elixir = beam-pkg.elixir_1_17;
      mixRelease = beam-pkg.mixRelease.override { inherit elixir; };
      elixir-ls = pkgs.elixir-ls.override { inherit elixir mixRelease; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
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

      # packages.${system}.default = mixRelease {
      #   inherit pname version;

      #   src = ./.;

      #   mixFodDeps = beam-pkg.fetchMixDeps {
      #     pname = "mix-deps-${pname}";
      #     inherit version;
      #     src = ./r;
      #     hash = "sha256-sMLIHpXEirMNiYJwLUvRv5ZJkPYJDwz6QFMGMiYDHro=";
      #   };
      # };
    };
}
