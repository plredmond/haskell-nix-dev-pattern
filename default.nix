{ config ? { /*allowBroken = true;*/ }, ... }:
let
  # function to fetch a pinned version of nixpkgs
  ## from https://vaibhavsagar.com/blog/2018/05/27/quick-easy-nixpkgs-pinning/
  fetcher = { owner, repo, rev, sha256, ... }: builtins.fetchTarball {
    inherit sha256;
    url = "https://github.com/${owner}/${repo}/archive/${rev}.tar.gz";
  };
  # fetch pinned version of nixpkgs
  ## `vnixpinupdater versions.json nixpkgs nixos-20.03` wrote versions.json
  nixpkgs = import
    (fetcher (builtins.fromJSON (builtins.readFile ./versions.json)).nixpkgs)
    { inherit config; };
  # optionally, override haskell compiler version and/or dependencies in nixpkgs
  haskellPackages = nixpkgs.haskellPackages;
  # function to bring in devtools
  devtools = old: { nativeBuildInputs = with nixpkgs.pkgs; old.nativeBuildInputs ++ [ cabal-install ghcid ]; }; # ghc and hpack are automatically included
  # ignore files specified by gitignore
  source = nixpkgs.nix-gitignore.gitignoreSource [] ./.;
  # use overridden-haskellPackages to call gitignored-source and produce either package or env
  drv = haskellPackages.callCabal2nix "abcexample" source {};
in
if nixpkgs.lib.inNixShell then drv.env.overrideAttrs devtools else drv
