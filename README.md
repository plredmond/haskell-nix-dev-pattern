# How to use

* Develop in `nix-shell` with `cabal v2-*` commands.
    * Do not run `cabal v2-*` commands outside of `nix-shell`, because that will do separate dependency resolution which may be distinct from nix and may break.
* Release with `nix-build`.
    * Do not run `nix-build` inside `nix-shell` because that won't produce a `result` containing your project.

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
