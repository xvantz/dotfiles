{...}: {
  programs.nixvim = {
    plugins.conform-nvim = {
      enable = true;

      lazy = [
        {event = "BufWritePre";}
        {command = "ConformInfo";}
      ];

      settings = {
        format_on_save = {
          timeout_ms = 3000;
          lsp_fallback = false;
        };

        formatters_by_ft = {
          lua = ["stylua"];
          python = ["ruff_format"];
          javascript = ["biome" "prettierd"];
          typescript = ["biome" "prettierd"];
          javascriptreact = ["biome" "prettierd"];
          typescriptreact = ["biome" "prettierd"];
          json = ["biome" "prettierd"];
          svelte = ["prettierd"];
          html = ["prettierd"];
          css = ["prettierd"];
          markdown = ["prettierd"];
          yaml = ["prettierd"];
          rust = ["rustfmt"];
          go = ["goimports" "gofmt"];
          nix = ["alejandra"];
          proto = ["buf_format"];
        };

        formatters = {
          stylua = {
            prepend_args = ["--indent-type" "Spaces" "--indent-width" "2"];
          };
        };
      };

      keys = [
        {
          mode = "n";
          key = "<leader>f";
          action.__raw = ''
            function()
              require("conform").format({ async = false, timeout_ms = 3000 })
            end
          '';
          options.desc = "Format Buffer";
        }
      ];
    };

    extraConfigLua = ''
      local conform = require("conform")

      conform.formatters.biome = {
        command = "biome",
        args = { "check", "--write", "$FILENAME" },
        stdin = false,
        condition = function(_, ctx)
          return vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = ctx.filename })[1]
        end,
      }

      conform.formatters.prettierd = {
        condition = function(_, ctx)
          local has_biome = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = ctx.filename })[1]
          return not has_biome or vim.bo[ctx.buf].filetype == "svelte"
        end,
      }

      vim.api.nvim_create_autocmd("User", {
        pattern = "ConformSetupPost",
        callback = function()
          local ft_list = { "javascript", "typescript", "javascriptreact", "typescriptreact", "json" }
          for _, ft in ipairs(ft_list) do
            local list = conform.formatters_by_ft[ft]
            if list then
              for i, fmt in ipairs(list) do
                if fmt == "biome" or fmt == "prettierd" then
                  list[i] = { name = fmt, stop_after_first = true }
                end
              end
            end
          end
        end,
      })
    '';
  };
}
