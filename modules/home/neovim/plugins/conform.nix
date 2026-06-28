{...}: {
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;

      lazyLoad = {
        enable = true;
        settings = {
          event = ["BufWritePre"];
          cmd = ["ConformInfo"];
        };
      };

      settings = {
        format_on_save = {
          timeout_ms = 3000;
          lsp_fallback = false;
        };

        formatters_by_ft = {
          lua = ["stylua"];
          python = ["ruff_format"];

          typescript = ["biome-organize-imports" "biome-check"];
          javascript = ["biome-organize-imports" "biome-check"];
          typescriptreact = ["biome-organize-imports" "biome-check"];
          javascriptreact = ["biome-organize-imports" "biome-check"];
          json = ["biome-organize-imports" "biome-check"];
          svelte = ["biome-organize-imports" "biome-check"];

          html = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };
          css = {
            __unkeyed-1 = "biome-check";
            __unkeyed-2 = "prettierd";
            stop_after_first = true;
          };

          markdown = ["prettierd"];
          yaml = ["prettierd"];
          rust = ["rustfmt"];
          go = ["goimports" "gofmt"];
          nix = ["alejandra"];
          proto = ["buf"];
        };

        formatters = {
          stylua = {
            prepend_args = ["--indent-type" "Spaces" "--indent-width" "2"];
          };
        };
      };
    };
  };
}
