{
  pkgs,
  customPkgs,
  inputs,
  ...
}: {
  programs.nixvim = {
    enable = true;
    nixpkgs = {
      source = inputs.nixpkgs;
    };

    version = {
      enableNixpkgsReleaseCheck = false;
    };

    globals.mapleader = " ";
    colorschemes.tokyonight = {
      enable = true;
    };

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
      updatetime = 200;
      timeoutlen = 400;
      smoothscroll = true;
      clipboard = "unnamedplus";
      scrolloff = 8;
      sidescrolloff = 8;
      undofile = true;
      pumblend = 10;
      winblend = 10;
      swapfile = false;
      inccommand = "split";
    };

    diagnostic.settings = {
      virtual_text = false;
      underline = true;
      update_in_insert = false;
      severity_sort = true;
      float = {
        border = "rounded";
        source = "always";
      };
      signs = {
        text.__raw = ''
          {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN]  = " ",
            [vim.diagnostic.severity.INFO]  = " ",
            [vim.diagnostic.severity.HINT]  = "󰌶 ",
          }
        '';
      };
    };

    extraPackages = with pkgs; [
      tree-sitter
      markdownlint-cli
      sass
      postcss
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
