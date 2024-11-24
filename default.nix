{
  nixpkgs ? import <nixpkgs> { },
}:

let
  beam-pkg = nixpkgs.beam.packagesWith nixpkgs.erlang_26;

  pname = "ha-notifier";
  version = "0.1.0";

  src = builtins.fetchGit {
    url = "ssh://git@github.com/cvincent/ha-notifier";
    ref = version;
  };

  mixFodDeps = beam-pkg.fetchMixDeps {
    pname = "mix-deps-${pname}";
    inherit src version;
    hash = nixpkgs.lib.fakeSha256;
  };
in
beam-pkg.mixRelease {
  inherit
    src
    pname
    version
    mixFodDeps
    ;
}
