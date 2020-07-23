{ config ? { /*allowBroken = true;*/ }, ... }:
let
  # fetch pinned version of nixpkgs
  nixpkgs = import (
    builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs-channels/archive/1a92d0abfcdbafc5c6e2fdc24abf2cc5e011ad5a.tar.gz";
      sha256 = "1f9ypp9q7r5p1bzm119yfg202fbm83csmlzwv33p1kf76m2p7mwd";
    }
  ) { inherit config; };
  # fetch pinned version of liquidhaskell
  lh-src = nixpkgs.fetchFromGitHub {
    owner = "ucsd-progsys";
    repo = "liquidhaskell";
    rev = "26cad4f05171669949fd92fa5a5f584a4950ca7b";
    sha256 = "1xvm005xhzlfm7b7hvc2jr667sgmy9mg47daiw6mmxkfblzjzafa";
  };
  # function to make sure a haskell package has z3 at build-time and test-time
  usingZ3 = pkg: nixpkgs.haskell.lib.overrideCabal pkg (old: { buildTools = old.buildTools or [] ++ [ nixpkgs.z3 ]; });
  # override haskell compiler version, add and override dependencies in nixpkgs
  haskellPackages = nixpkgs.haskell.packages."ghc8101".override (
    old: {
      all-cabal-hashes = nixpkgs.fetchurl {
        url = "https://github.com/commercialhaskell/all-cabal-hashes/archive/0bd3bb7eb8c998872a4b1a0ee83d8c619228ac2a.tar.gz";
        sha256 = "00x1830xqlpadc8zyn90yw6h19ir55l8nz20i36j0aky0c1dgkfm";
      };
      overrides = self: super: with nixpkgs.haskell.lib; rec {
        # parts of liquidhaskell are not yet on hackage, and the hackage version is old, so here we build all needed components from source
        liquid-base =
          dontHaddock (
            usingZ3 (
              self.callCabal2nix "liquid-base" (lh-src + "/liquid-base")
                { inherit liquid-ghc-prim; inherit liquidhaskell; }
            )
          );
        liquid-ghc-prim =
          dontHaddock (
            usingZ3 (
              self.callCabal2nix "liquid-ghc-prim" (lh-src + "/liquid-ghc-prim")
                { inherit liquidhaskell; }
            )
          );
        liquidhaskell =
          dontCheck (
            self.callCabal2nix "liquidhaskell" lh-src
              { inherit liquid-fixpoint; }
          );
        liquid-fixpoint =
          self.callCabal2nix "liquid-fixpoint" (
            nixpkgs.fetchFromGitHub {
              owner = "ucsd-progsys";
              repo = "liquid-fixpoint";
              rev = "a4e303bc55e8f596893e661954e20c983a61215f";
              sha256 = "0md40v4dkps370idf66fhskbr3hhvd65ipx8ygvchpsqrpiskhql";
            }
          ) {};
        # some dependencies of liquidhaskell had problems with version ranges or tests
        ChasingBottoms = doJailbreak super.ChasingBottoms;
        Diff = dontCheck super.Diff;
        hashable = self.callHackage "hashable" "1.3.0.0" {}; # ouch
        inspection-testing = self.callHackage "inspection-testing" "0.4.2.4" {};
        optics = self.callHackage "optics" "0.3" {};
        optics-core = self.callHackage "optics-core" "0.3" {};
        optics-extra = self.callHackage "optics-extra" "0.3" {};
        optics-th = self.callHackage "optics-th" "0.3" {};
        tasty-rerun = doJailbreak super.tasty-rerun;
        text-format = doJailbreak super.text-format;
        # also fix doctest
        doctest = dontCheck (self.callHackage "doctest" "0.16.3" {});
      };
    }
  );
  # function to manually run doctest in the nix-build environment
  usingDoctest = pkg: nixpkgs.haskell.lib.overrideCabal pkg (old: { preCheck = "${nixpkgs.python3}/bin/python gen-ghc-env.py base"; });
  # function to bring devtools in to a package environment
  devtools = old: { nativeBuildInputs = old.nativeBuildInputs ++ [ nixpkgs.cabal-install nixpkgs.ghcid ]; }; # ghc and hpack are automatically included
  # ignore files specified by gitignore in nix-build
  source = nixpkgs.nix-gitignore.gitignoreSource [] ./.;
  # use overridden-haskellPackages to call gitignored-source
  drv =
    usingDoctest (
      usingZ3 (
        nixpkgs.haskell.lib.dontHaddock (
          haskellPackages.callCabal2nix "abcexample" source {}
        )
      )
    );
in
if nixpkgs.lib.inNixShell then drv.env.overrideAttrs devtools else drv
