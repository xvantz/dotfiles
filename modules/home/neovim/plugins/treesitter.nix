{config, ...}: {
  programs.nixvim = {
    plugins.lz-n.enable = true;

    plugins.treesitter = {
      enable = true;

      grammarPackages = with config.programs.nixvim.plugins.treesitter.package.builtGrammars; [
        bash
        go
        gomod
        javascript
        lua
        markdown
        markdown_inline
        nix
        proto
        rust
        scss
        svelte
        tsx
        typescript
        typst
        yaml
        zig
      ];
    };
  };
}
