{...}: {
  programs.nixvim.plugins.blink-cmp = {
    enable = true;

    settings = {
      keymap = {
        preset = "super-tab";
      };

      sources = {
        default = ["lsp" "path" "snippets" "buffer"];
        providers = {
          lsp = {score_offset = 2;};
          path = {score_offset = 1;};
          snippets = {score_offset = 0;};
          buffer = {score_offset = -1;};
        };
      };

      completion = {
        trigger = {
          show_on_keyword = true;
        };
        menu = {
          auto_show = true;
          draw = {
            treesitter = ["lsp"];
            columns = [
              ["label" "label_description"]
              ["kind_icon" "kind"]
            ];
          };
        };
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
          treesitter_highlighting = true;
        };
      };

      signature = {
        enabled = true;
        window = {
          show_documentation = true;
          border = "rounded";
        };
      };

      fuzzy = {
        implementation = "prefer_rust_with_warning";
      };

      cmdline = {
        keymap = {
          preset = "inherit";
        };
        completion = {
          menu = {
            auto_show.__raw = ''
              function()
                local t = vim.fn.getcmdtype()
                return t == ":" or t == "@"
              end
            '';
          };
        };
      };
    };
  };
}
