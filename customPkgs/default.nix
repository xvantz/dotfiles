pkgs: {
  codex = pkgs.callPackage ./codex/codex.nix {};
  gemini = pkgs.callPackage ./gemini/gemini.nix {};
  biome = pkgs.callPackage ./biome/biome.nix {};
  pi-coding = pkgs.callPackage ./pi-coding-agent/pi.nix {};
}
