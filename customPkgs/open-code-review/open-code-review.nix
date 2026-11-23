{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "1.13.13";

  # Готовые бинарники из GitHub Releases. Собирать из исходников смысла нет:
  # релизы выходят раз в пару недель, а Go-сборка тянет весь тулчейн в замыкание.
  sources = {
    x86_64-linux = {
      suffix = "linux-amd64";
      hash = "sha256-4+tjTIIFoSDBbplD3gCu+JXizYbWsTw44lQnySQnXsg=";
    };
    aarch64-linux = {
      suffix = "linux-arm64";
      hash = "sha256-sXR9xKQfS8ED6Lz3qKXB/1UacxIWtrYyatm4yihQsm4=";
    };
    x86_64-darwin = {
      suffix = "darwin-amd64";
      hash = "sha256-eWeV+4TqycT/KD4ccG1gbgeGlJpd8jjRMWt2NDD1Rf4=";
    };
    aarch64-darwin = {
      suffix = "darwin-arm64";
      hash = "sha256-4KFma7AAZdE9p1XVwPcU1na+UIfSVExfE0jaSiBbk9Y=";
    };
  };

  current =
    sources.${stdenv.hostPlatform.system}
      or (throw "open-code-review: нет бинарника для ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "open-code-review";
  inherit version;

  src = fetchurl {
    url = "https://github.com/alibaba/open-code-review/releases/download/v${version}/opencodereview-${current.suffix}";
    inherit (current) hash;
  };

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/bin/ocr
    runHook postInstall
  '';

  meta = with lib; {
    description = "AI code review CLI: deterministic pipeline plus LLM agent (Alibaba OpenCodeReview)";
    homepage = "https://github.com/alibaba/open-code-review";
    changelog = "https://github.com/alibaba/open-code-review/releases/tag/v${version}";
    license = licenses.asl20;
    mainProgram = "ocr";
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  };
}
