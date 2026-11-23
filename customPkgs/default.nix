final: prev: {
  xv-biome = prev.callPackage ./biome/biome.nix {};
  xv-driftty-terminal = prev.callPackage ./driftty-terminal/driftty-terminal.nix {};
  xv-open-code-review = prev.callPackage ./open-code-review/open-code-review.nix {};
}
