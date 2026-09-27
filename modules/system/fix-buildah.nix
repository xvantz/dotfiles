{ lib, pkgs, ... }: {
  nixpkgs.overlays = [
    (final: prev: {
      buildah = prev.buildah.overrideAttrs (o: {
        patches = (o.patches or []) ++ [
          (prev.fetchpatch {
            url = "https://github.com/containers/buildah/pull/7129.patch";
            hash = "sha256-t648PPyny/gixGAOUTyxCTi2pga5fEo4os62zhxnMKQ=";
          })
        ];
      });
    })
  ];

  warnings = [
    "fix-buildah overlay active — remove modules/system/fix-buildah.nix when nixpkgs provides buildah 1.45.2+ (podman#29805)"
  ];
}
