# How to use

* Develop in `nix-shell` with `cabal v2-*` commands.
    * Do not run `cabal v2-*` commands outside of `nix-shell`, because that will do separate dependency resolution which may be distinct from nix and may break.
* Release with `nix-build`.
    * Do not run `nix-build` inside `nix-shell` because that won't produce a `result` containing your project.

# Doctest sharp edges

Tests are implemented with doctest, which currently requires `.ghc.environment*` files to be present.
As of cabal 3, `.ghc.environment*` files aren't written by default and you'll need to add a snippet of configuration to get them back.

`~/.cabal/config` or `cabal.project.local`
```
write-ghc-environment-files: always
```

To test, you'll need to run cabal once to write out the `.ghc.environment*` file, during which the tests will fail, and a second time to actually run the tests. See the hook below for an example of this.

However the presence of the `ghc.environment*` files can break `nix-build` and so we use `nix-gitignore` in `default.nix` to generate the list passed to `callCabal2nix` excluding the `.ghc.environment*` files per the `.gitignore`.

# Git hook

You might want a pre-commit hook to run tests.

`.git/hooks/pre-commit`
```sh
#!/usr/bin/env bash
set -e -u -o pipefail
set -x
if [ -n "${IN_NIX_SHELL:-}" ]; then
    # v2-build must run first to write out a .ghc.environment* file for doctest to use
    cabal v2-build --write-ghc-environment-files=always
    cabal v2-test
else
    # if a .ghc.environment* file is around, it must be ignored or it will break the isolated nix-build
    nix-build

    # also test cabal here for good measure
    nix-shell --run 'cabal v2-build --write-ghc-environment-files=always && cabal v2-test'
fi
```

# Bashrc aliases

You might want aliases to remind you not to use cabal commands outside of `nix-shell` and not to use nix commands inside of `nix-shell`.

`~/.bashrc`
```sh
# only use cabal/ghc/ghcid while in a project's nix-shell environment;
# rely on nix for dependency resolution
function require_nix_shell {
    if [ -z "$IN_NIX_SHELL" ]; then
        echo try again in nix-shell
        return
    fi
    "$@"
}
alias cabal='require_nix_shell cabal'
alias ghc='require_nix_shell ghc'
alias ghcid='require_nix_shell ghcid'
```
```sh
# only use nix-build outside of nix-shell;
# the result produced from within nix-shell is not useful
function disallow_nix_shell {
    if [ -n "$IN_NIX_SHELL" ]; then
        echo try again outside of nix-shell
        return
    fi
    "$@"
}
alias nix-build='disallow_nix_shell nix-build'
```
