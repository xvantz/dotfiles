{
  pkgs,
  pkgs-unstable,
  customPkgs,
  ...
}: {
  programs.nixvim = {
    enable = true;
    globals.mapleader = " ";
    colorschemes.tokyonight.enable = true;

    opts = {
      fileformats = "unix,dos";
      fileformat = "unix";
      fixendofline = true;
      endofline = true;
      bomb = false;
      termguicolors = true;
      number = true;
      relativenumber = true;
      signcolumn = "yes";
      cursorline = true;
      splitright = true;
      splitbelow = true;
      wrap = true;
      linebreak = true;
      showbreak = "↪ ";
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;
      updatetime = 200;
      timeoutlen = 400;
      clipboard = "unnamedplus";
    };

    diagnostic = {
      virtual_text = {
        spacing = 2;
        prefix = "●";
      };
      underline = true;
      update_in_insert = false;
      float = {
        border = "rounded";
        source = "if_many";
      };
      severity_sort = true;
      signs.text = {
        error = " ";
        warn = " ";
        hint = "󰌶 ";
        info = " ";
      };
    };

    extraPackages = with pkgs; [
      pkgs-unstable.tree-sitter
      markdownlint-cli
      sass
      nodePackages.postcss
      selene
      stylua
      prettierd
      eslint_d
      black
      customPkgs.biome
      buf
      gotools
      ruff
      ghostscript
      mermaid-cli
      tectonic
      typescript
      ty
    ];
  };
}
