{
  pkgs,
  pkgs-unstable,
  config,
  selfPath,
  customPkgs,
  ...
}: {
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${selfPath}/config/nvim";

  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      tree-sitter
      pkgs-unstable.tree-sitter-grammars.tree-sitter-svelte
      pkgs-unstable.tree-sitter-grammars.tree-sitter-typescript
      nodePackages.markdownlint-cli
      nodePackages.tailwindcss
      nodePackages.svelte-language-server
      nodePackages.sass
      nodePackages.postcss
      selene
      lua-language-server
      stylua
      zls
      vtsls
      gopls
      rustfmt
      rust-analyzer
      csharp-ls
      vscode-langservers-extracted
      marksman
      prettierd
      eslint_d
      black
      customPkgs.biome
    ];
  };
}
