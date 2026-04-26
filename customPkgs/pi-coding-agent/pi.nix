{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  makeWrapper,
  ripgrep,
  nodejs,
  typescript,
  plugins ? [],
}:
buildNpmPackage (finalAttrs: {
  pname = "pi-coding-agent";
  version = "0.67.68";

  src = fetchFromGitHub {
    owner = "badlogic";
    repo = "pi-mono";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1k9tHb5Dle37a5qHm8xT14vI5cQZOb8ASGQ1KxzPCr4=";
  };

  npmDepsHash = "sha256-xQQZECkDuiCdu0FlKbAKgk6EatLf2jMIXKDfRRwN/gA=";

  npmWorkspace = "packages/coding-agent";
  npmRebuildFlags = ["--ignore-scripts"];

  nativeBuildInputs = [makeWrapper];

  runtimeDeps =
    [
      ripgrep
      nodejs
      typescript
    ]
    ++ plugins;

  buildPhase = ''
    runHook preBuild

    npx tsgo -p packages/ai/tsconfig.build.json
    npx tsgo -p packages/tui/tsconfig.build.json
    npx tsgo -p packages/agent/tsconfig.build.json
    npm run build --workspace=packages/coding-agent

    runHook postBuild
  '';

  postInstall = ''
    local nm="$out/lib/node_modules/pi-monorepo/node_modules"

    for ws in @mariozechner/pi-ai:packages/ai \
              @mariozechner/pi-agent-core:packages/agent \
              @mariozechner/pi-tui:packages/tui; do
      IFS=: read -r pkg src <<< "$ws"
      rm "$nm/$pkg"
      cp -r "$src" "$nm/$pkg"
    done

    find "$nm" -type l -lname '*/packages/*' -delete
    find "$nm/.bin" -xtype l -delete

    mkdir -p $out/share/pi/extensions

    ${lib.concatMapStringsSep "\n" (plugin: ''
        echo "Linking plugin: ${plugin.name or "unnamed-plugin"}"
        ln -s ${plugin} $out/share/pi/extensions/${lib.removePrefix "pi-ext-" (plugin.pname or "ext")}
      '')
      plugins}
  '';

  postFixup = ''
    wrapProgram $out/bin/pi \
      --prefix PATH : ${lib.makeBinPath finalAttrs.runtimeDeps} \
      --set PI_NIX_EXTENSIONS "$out/share/pi/extensions" \
      --add-flags "--extension $out/share/pi/extensions"
  '';

  meta = {
    description = "Extensible Coding agent CLI (Nix-optimized)";
    homepage = "https://shittycodingagent.ai/";
    license = lib.licenses.mit;
    mainProgram = "pi";
  };
})
