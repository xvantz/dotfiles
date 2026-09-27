{ lib, pkgs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      podman = prev.podman.overrideAttrs (o: {
        patches = (o.patches or []) ++ [
          (prev.fetchpatch {
            url = "https://github.com/containers/buildah/pull/7129.patch";
            hash = "sha256-t648PPyny/gixGAOUTyxCTi2pga5fEo4os62zhxnMKQ=";
            stripLen = 1;
            extraPrefix = "vendor/github.com/containers/buildah/";
          })
        ];
      });
    })
  ];

  warnings = [
    "fix-podman overlay active — remove modules/system/fix-buildah.nix when nixpkgs gives podman 5.8.8+ (podman#29805)"
  ];
}
