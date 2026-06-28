{...}: {
  programs.nixvim.keymaps = [
    {
      mode = "i";
      key = "jj";
      action = "<Esc>";
      options = {
        desc = "Exit insert (jj)";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>w";
      action = "<cmd>w<cr>";
      options = {
        desc = "Save";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>q";
      action = "<cmd>q<cr>";
      options = {
        desc = "Quit";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "K";
      action.__raw = "function() vim.lsp.buf.hover({ border = 'rounded' }) end";
      options = {
        desc = "Hover";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>ca";
      action.__raw = "vim.lsp.buf.code_action";
      options = {
        desc = "Code Action";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>rn";
      action.__raw = "vim.lsp.buf.rename";
      options = {
        desc = "Rename";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "gd";
      action.__raw = "function() Snacks.picker.lsp_definitions() end";
      options = {desc = "LSP: Goto Definition";};
    }
    {
      mode = "n";
      key = "gr";
      action.__raw = "function() Snacks.picker.lsp_references() end";
      options = {
        desc = "LSP: References";
        nowait = true;
      };
    }
    {
      mode = "n";
      key = "gi";
      action.__raw = "function() Snacks.picker.lsp_implementations() end";
      options = {desc = "LSP: Goto Implementation";};
    }
    {
      mode = "n";
      key = "<leader>gg";
      action.__raw = "function() Snacks.lazygit.open() end";
      options = {desc = "LazyGit: Open";};
    }
    {
      mode = "n";
      key = "<leader>gl";
      action.__raw = "function() Snacks.lazygit.log_file() end";
      options = {desc = "LazyGit: Log";};
    }
    {
      mode = "n";
      key = "<leader>sn";
      action.__raw = "function() Snacks.picker.notifications() end";
      options = {desc = "Notifications";};
    }
    {
      mode = ["n" "t"];
      key = "<C-\\>";
      action.__raw = "function() Snacks.terminal.toggle() end";
      options = {desc = "Toggle terminal";};
    }
    {
      mode = "n";
      key = "<leader>e";
      action.__raw = "function() Snacks.explorer.open() end";
      options = {desc = "Explorer: Open";};
    }
    {
      mode = "n";
      key = "<leader>ff";
      action.__raw = "function() Snacks.picker.files() end";
      options = {desc = "Find files";};
    }
    {
      mode = "n";
      key = "<leader>fg";
      action.__raw = "function() Snacks.picker.grep() end";
      options = {desc = "Live grep";};
    }
    {
      mode = "n";
      key = "<leader>fb";
      action.__raw = "function() Snacks.picker.buffers() end";
      options = {desc = "Buffers";};
    }
    {
      mode = ["n" "x"];
      key = "<leader>fw";
      action.__raw = "function() Snacks.picker.grep_word() end";
      options = {desc = "Find word under cursor";};
    }
    {
      mode = "n";
      key = "<leader>sd";
      action.__raw = "function() Snacks.picker.diagnostics_buffer() end";
      options = {desc = "Diagnostics (buffer)";};
    }
    {
      mode = "n";
      key = "<leader>x";
      action.__raw = ''
        function()
          local buffers = vim.fn.getbufinfo({ buflisted = 1 })
          local success = Snacks.bufdelete()
          if not success then return end
          if #buffers <= 1 then Snacks.dashboard.open() end
        end
      '';
      options = {desc = "Close Buffer & fallback to dashboard";};
    }
    {
      mode = "n";
      key = "<leader>ft";
      action.__raw = "function() Snacks.picker.todo_comments() end";
      options = {desc = "Todo comments";};
    }
    {
      mode = "n";
      key = "<C-h>";
      action.__raw = "require('smart-splits').move_cursor_left";
      options = {
        desc = "Go to left split";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-j>";
      action.__raw = "require('smart-splits').move_cursor_down";
      options = {
        desc = "Go to bottom split";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-k>";
      action.__raw = "require('smart-splits').move_cursor_up";
      options = {
        desc = "Go to top split";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<C-l>";
      action.__raw = "require('smart-splits').move_cursor_right";
      options = {
        desc = "Go to right split";
        silent = true;
      };
    }
    {
      mode = "n";
      key = "<leader>rr";
      action = "<cmd>OverseerRun<CR>";
      options.desc = "Overseer: Run task";
    }
    {
      mode = "n";
      key = "<leader>rt";
      action = "<cmd>OverseerToggle!<CR>";
      options.desc = "Overseer: Toggle panel";
    }
    {
      mode = "n";
      key = "<leader>rs";
      action.__raw = ''
        function()
          vim.ui.input({
            prompt = "Overseer shell> ",
            default = "",
          }, function(cmdline)
            if cmdline == nil or cmdline:match("^%s*$") then
              print("Task cancelled or empty.")
              return
            end
            vim.cmd("OverseerShell " .. cmdline)
          end)
        end
      '';
      options.desc = "Overseer: run shell command";
    }
    {
      mode = "n";
      key = "<leader>fo";
      action.__raw = ''
        function()
          require("conform").format({ async = false, timeout_ms = 3000 })
        end
      '';
      options = {
        desc = "Format Buffer";
        silent = true;
      };
    }
    {
      mode = ["n" "x" "o"];
      key = "s";
      action = "<Plug>(leap)";
      options = {desc = "Leap forward to";};
    }
    {
      mode = "n";
      key = "S";
      action = "<Plug>(leap-from-window)";
      options = {desc = "Leap from window";};
    }
  ];
}
