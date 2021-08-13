#!/usr/bin/env sh

nix-build '<nixpkgs/nixos>' -A vm --arg configuration ./configuration.nix
