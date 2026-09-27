{ lib, pkgs, inputs, ... }:
let
  pinnedPkgs = inputs.nixpkgs-podman-pin.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  # Temporary pin: podman 5.8.6 — 5.8.7 breaks Forgejo runner
  # (CopyToContainer "path escapes from parent" on /var/run -> /run, podman#29805).
  virtualisation.podman.package = pinnedPkgs.podman;

  warnings = lib.optional (lib.versionAtLeast pkgs.podman.version "5.8.8")
    "podman 5.8.8+ has landed in nixpkgs — remove modules/system/fix-podman.nix and the nixpkgs-podman-pin input (podman#29805 fixed upstream)";
}
