{
  lib,
  stdenv,
  fetchurl,
}:
stdenv.mkDerivation rec {
  pname = "biome";
  version = "2.4.4";

  src = fetchurl {
    url = "https://github.com/biomejs/biome/releases/download/%40biomejs%2Fbiome%40${version}/biome-linux-x64";
    hash = "sha256-ulBzAX7AOnAOW5JwskVN99vsalEkYRu3hbaK5xdQbUU=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp $src $out/bin/biome
    chmod +x $out/bin/biome
    runHook postInstall
  '';

  meta = with lib; {
    description = "Toolchain of the web (Binary version)";
    homepage = "https://biomejs.dev/";
    license = licenses.mit;
    mainProgram = "biome";
    platforms = ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
  };
}
