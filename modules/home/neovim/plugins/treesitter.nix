{...}: {
  programs.nixvim.plugins.treesitter = {
    enable = true;
    grammars = [
      "go"
      "gomod"
      "typescript"
      "tsx"
      "javascript"
      "lua"
      "markdown"
      "markdown_inline"
      "proto"
      "nix"
      "bash"
      "svelte"
      "latex"
      "scss"
      "typst"
      "rust"
      "zig"
      "norg"
    ];
  };
}
