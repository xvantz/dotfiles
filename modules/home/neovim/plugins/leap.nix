{...}: {
  programs.nixvim = {
    plugins.leap = {
      enable = true;

      settings = {
        highlight_unlabeled_phase_one_targets = true;
        safe_labels = "sfjklhodweiraumbcvgt";
        labels = "sfnjklhodweiraumbcvgt";
      };
    };

    extraConfigLua = ''
      -- Leap.nvim custom highlights
      vim.api.nvim_set_hl(0, "LeapBackdrop", { link = "Comment" })
      vim.api.nvim_set_hl(0, "LeapMatch", { fg = "#f5c2e7", bold = true, underline = true })
      vim.api.nvim_set_hl(0, "LeapLabelPrimary", { fg = "#1e1e2e", bg = "#cba6f7", bold = true })
    '';
  };
}
