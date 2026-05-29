{...}: {
  programs.nixvim.plugins.noice = {
    enable = true;

    settings = {
      lsp = {
        hover = {
          enabled = true;
          silent = false;
          view = "popup";
        };

        signature = {
          enabled = true;
          view = "popup";
        };
      };
      presets = {
        lsp_doc_border = true;
      };
    };
  };
}
