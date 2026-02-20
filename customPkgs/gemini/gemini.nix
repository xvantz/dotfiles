{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
}:
stdenv.mkDerivation rec {
  pname = "gemini-cli";
  version = "0.29.5";

  src = fetchurl {
    url = "https://github.com/google-gemini/gemini-cli/releases/download/v${version}/gemini.js";
    hash = "sha256-Yzqi2l41XLNMGNqeVGru0SALc1ZVa2LS4Qk2QiiSasY=";
  };

  unpackPhase = "true";

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/gemini-cli

    cp $src $out/share/gemini-cli/gemini.js

    makeWrapper ${nodejs}/bin/node $out/bin/gemini \
      --add-flags "$out/share/gemini-cli/gemini.js" \
      --set DISABLE_AUTOUPDATER 1
  '';

  meta = with lib; {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    mainProgram = "gemini";
    platforms = platforms.all;
  };
}
