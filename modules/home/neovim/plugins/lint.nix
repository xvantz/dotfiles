{pkgs, ...}: {
  programs.nixvim = {
    plugins.lint = {
      enable = true;
      lazy = [{event = ["BufReadPre" "BufNewFile"];}];

      settings = {
        linters_by_ft = {
          nix = ["statix"];
          python = ["ruff" "check"];
          lua = ["selene"];
          markdown = ["markdownlint"];
          sh = ["shellcheck"];
        };
      };
    };

    extraPackages = [pkgs.statix];

    extraConfigLua = ''
      local lint = require("lint")

      local function get_js_linters()
        local root = vim.fs.find(
          { "biome.json", "biome.jsonc", ".eslintrc", ".eslintrc.js", ".eslintrc.json", "eslint.config.js" },
          { upward = true, path = vim.api.nvim_buf_get_name(0) }
        )[1]
        if not root then return {} end

        local filename = vim.fn.fnamemodify(root, ":t")
        if filename:find("biome")   then return { "biomejs" }   end
        if filename:find("eslint")  then return { "eslint_d" } end
        return {}
      end

      local js_ft = { "javascript", "typescript", "javascriptreact", "typescriptreact" }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        callback = function()
          local ft = vim.bo.filetype
          if vim.list_contains(js_ft, ft) then
            lint.try_lint(get_js_linters())
          else
            lint.try_lint()
          end
        end,
      })
    '';
  };
}
