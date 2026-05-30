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
          draw.__raw = ''
            {
              treesitter = { "lsp" },
              columns = {
                { "kind_icon", gap = 1 },
                { "label", "label_description", gap = 1 },
              },
              padding = { 0, 1 },
              components = {
                label = {
                  width = { fill = true }
                },
                label_description = { highlight = "BlinkCmpLabelDescription" },
              }
            }
          '';
        };
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
          draw.__raw = ''
            function(opts)
              opts.default_implementation()
            end
          '';
          treesitter_highlighting = true;
          window = {
            border = "rounded";
          };
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
