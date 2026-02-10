pkgs: {
  codex = pkgs.callPackage ./codex/codex.nix {};
  gemini = pkgs.callPackage ./codex/gemini.nix {};
}
