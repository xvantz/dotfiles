pkgs: {
  codex = pkgs.callPackage ./codex/codex.nix {};
  gemini = pkgs.callPackage ./gemini/gemini.nix {};
}
