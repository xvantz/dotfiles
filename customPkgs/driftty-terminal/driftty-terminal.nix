{
  lib,
  stdenv,
  fetchurl,
}:
let
  pname = "driftty-terminal";
  version = "3.0.0";

  platforms = {
    "x86_64-linux" = {
      target = "x86_64";
      hash = "sha256-dKic2xP8BNamDpLQBG9MGkh0cUWp6G1fwZv9Kw6Czdk=";
    };
    "aarch64-linux" = {
      target = "aarch64";
      hash = "sha256-rkscgyTTJUA9iyFy21pbKx1gwsLygCyXOP9EGESWXlM=";
    };
  };

  currArch = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/mdp/driftty/releases/download/v${version}/driftty-terminal-linux-${currArch.target}.tar.gz";
    sha256 = currArch.hash;
  };

  unpackPhase = "tar -xzf $src";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/doc/driftty-terminal
    cp driftty-terminal $out/bin/driftty-terminal
    chmod +x $out/bin/driftty-terminal
    cp README.md VERSION LICENSES.txt $out/share/doc/driftty-terminal/ || true

    runHook postInstall
  '';

  # Statically linked with musl, no patchelf needed.

  meta = with lib; {
    description = "Mobile-first web terminal (ttyd + embedded UI), standalone binary";
    homepage = "https://github.com/mdp/driftty";
    license = licenses.mit;
    mainProgram = "driftty-terminal";
    platforms = builtins.attrNames platforms;
  };
}
