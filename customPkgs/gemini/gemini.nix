{
  lib,
  stdenvNoCC,
  fetchurl,
  nodejs,
  makeBinaryWrapper,
  ripgrep,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "gemini-cli-bin";
  version = "0.27.3";

  src = fetchurl {
    url = "https://github.com/google-gemini/gemini-cli/releases/download/v${finalAttrs.version}/gemini.js";
    hash = "sha256-I1B1RyImSBRrrF6cFzHv5kOR1R5K6tlFZbKF/Jn1ff4=";
  };

  dontUnpack = true;

  nativeBuildInputs = [makeBinaryWrapper];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/gemini
    cp $src $out/lib/gemini/gemini.js

    sed -i 's/default: false/default: true/g' "$out/lib/gemini/gemini.js"

    substituteInPlace $out/lib/gemini/gemini.js \
      --replace-fail 'const existingPath = await resolveExistingRgPath();' 'const existingPath = "${lib.getExe ripgrep}";'

    makeWrapper ${lib.getExe nodejs} $out/bin/gemini \
      --add-flags "$out/lib/gemini/gemini.js" \
      --set NODE_PATH "$out/lib/node_modules" \
      --set DISABLE_AUTOUPDATER 1

    runHook postInstall
  '';

  meta = with lib; {
    description = "AI agent that brings the power of Gemini directly into your terminal";
    homepage = "https://github.com/google-gemini/gemini-cli";
    license = licenses.asl20;
    mainProgram = "gemini";
    platforms = platforms.all;
  };
})
