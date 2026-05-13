{
  pkgs,
  lib,
  extensions ? [],
}: let
  runtimeDeps = with pkgs;
    [
      nodejs
      git
      ripgrep
      fd
      jq
    ]
    ++ lib.flatten (
      map (x: x.runtimeDeps or []) extensions
    );
in
  pkgs.stdenvNoCC.mkDerivation rec {
    pname = "pi";
    version = "0.74.0";

    src = pkgs.fetchurl {
      url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";

      hash = "sha256-1nZXow1JyfrKgIaNKkvbpN/KwEcCiT9FptFLJJNF640=";
    };

    nativeBuildInputs = [
      pkgs.makeWrapper
    ];

    dontBuild = true;

    unpackPhase = ''
      mkdir source
      tar -xzf $src -C source --strip-components=1
      cd source
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      mkdir -p $out/share/pi

      cp -r ./* $out/share/pi/

      chmod +x $out/share/pi/pi

      runHook postInstall
    '';

    postFixup = ''
      makeWrapper $out/share/pi/pi $out/bin/pi \
        --prefix PATH : ${lib.makeBinPath runtimeDeps}
    '';

    passthru = {
      inherit extensions;
    };

    meta = {
      mainProgram = "pi";
      description = "Pi coding agent";
      homepage = "https://github.com/earendil-works/pi";
      license = lib.licenses.mit;
    };
  }
