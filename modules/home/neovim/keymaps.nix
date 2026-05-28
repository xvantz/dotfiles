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
      action.__raw = "vim.lsp.buf.hover";
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
  ];
}
