#!/usr/bin/env sh

NIXOS_CONFIG=$(pwd)/configuration.nix
export NIXOS_CONFIG
nixos-rebuild build-vm -I nixpkgs=/home/kai/sw/foss/nixpkgs/
