{
  lib,
  stdenv,
  fetchurl,
  gnutar,
  gzip,
}:
let
  version = "0.16.0";
  systemMap = {
    "x86_64-linux" = "agent-lsp_linux_amd64.tar.gz";
    "aarch64-linux" = "agent-lsp_linux_arm64.tar.gz";
    "x86_64-darwin" = "agent-lsp_darwin_amd64.tar.gz";
    "aarch64-darwin" = "agent-lsp_darwin_arm64.tar.gz";
  };
  arch = systemMap.${stdenv.system} or (throw "Unsupported system: ${stdenv.system}");
in
stdenv.mkDerivation rec {
  pname = "agent-lsp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/blackwell-systems/agent-lsp/releases/download/v${version}/${arch}";
    hash = "sha256-ZzGQM2hb7tciZix7tUrCJcTMZR1OCs1RrmHlDQLLtlo=";
  };

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [ gnutar gzip ];

  unpackPhase = ''
    mkdir -p extracted
    tar xzf $src -C extracted
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin
    cp extracted/agent-lsp $out/bin/
    chmod +x $out/bin/agent-lsp
    runHook postInstall
  '';

  meta = with lib; {
    description = "MCP server that orchestrates language servers into agent-native workflows. 65 tools, 30 CI-verified languages.";
    homepage = "https://github.com/blackwell-systems/agent-lsp";
    license = licenses.mit;
    mainProgram = "agent-lsp";
    platforms = builtins.attrNames systemMap;
  };
}
