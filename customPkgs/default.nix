final: prev: {
  xv-codex = prev.callPackage ./codex/codex.nix {};
  xv-gemini = prev.callPackage ./gemini/gemini.nix {};
  xv-biome = prev.callPackage ./biome/biome.nix {};
  xv-pi-coding = prev.callPackage ./pi-coding-agent/pi.nix {};
}
