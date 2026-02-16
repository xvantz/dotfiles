{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  openssl,
  libcap,
  patchelf,
  gnutar,
  gzip,
}: let
  pname = "codex";
  version = "0.98.0";

  platforms = {
    "aarch64-darwin" = {
      target = "aarch64-apple-darwin";
      hash = "0mc207isdh5jwwiy02y6rv3an04r1lhniiclr72f1bh3i1r5girw";
    };
    "x86_64-darwin" = {
      target = "x86_64-apple-darwin";
      hash = "012kbvgsrzas5fcz57sx9gf214djjw37hlhgmzxv3xfvh4sl330h";
    };
    "x86_64-linux" = {
      target = "x86_64-unknown-linux-gnu";
      hash = "0h0d961m60ybashw2lnkxyynidj8zgxnffhvcm8mf5b425vpjrmj";
    };
    "aarch64-linux" = {
      target = "aarch64-unknown-linux-gnu";
      hash = "00a78qcafn8ha10c1brkd4xd0sh8fqzbw7a45r3iirqh92fcs3ib";
    };
  };

  currArch = platforms.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    inherit pname version;

    src = fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-${currArch.target}.tar.gz";
      sha256 = currArch.hash;
    };

    nativeBuildInputs =
      [gnutar gzip makeBinaryWrapper]
      ++ lib.optional stdenv.isLinux patchelf;

    buildInputs = [openssl libcap];

    sourceRoot = ".";
    unpackPhase = "tar -xzf $src";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin
      cp codex-${currArch.target} $out/bin/.codex-wrapped

      ${lib.optionalString stdenv.isLinux ''
        patchelf \
          --set-interpreter "$(cat ${stdenv.cc}/nix-support/dynamic-linker)" \
          --set-rpath "${lib.makeLibraryPath [openssl libcap]}" \
          $out/bin/.codex-wrapped
      ''}

      makeWrapper $out/bin/.codex-wrapped $out/bin/codex \
        --set DISABLE_AUTOUPDATER 1 \
        --set CODEX_EXECUTABLE_PATH "$HOME/.local/bin/codex"

      runHook postInstall
    '';

    meta = with lib; {
      description = "OpenAI Codex CLI - AI coding assistant in your terminal";
      homepage = "https://github.com/openai/codex";
      license = licenses.asl20;
      mainProgram = "codex";
      platforms = builtins.attrNames platforms;
    };
  }
