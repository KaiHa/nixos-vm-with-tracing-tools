#!/usr/bin/env sh
set -ex

nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix --out-link ./result.native
nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix --out-link ./result.aarch64 --system aarch64-linux
