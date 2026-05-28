{...}: {
  programs.nixvim.plugins.snacks = {
    enable = true;

    settings = {
      bigfile.enabled = true;
      statuscolumn.enabled = true;
      words.enabled = true;
      image.enabled = true;
      scroll.enabled = true;
      picker = {
        enabled = true;
        ui_select = true;
      };
      terminal = {
        win = {style = "terminal";};
      };
      notifier = {
        enabled = true;
        timeout = 3000;
        width = {
          min = 40;
          max = 0.4;
        };
        height = {
          min = 1;
          max = 0.6;
        };
        margin = {
          top = 0;
          right = 1;
          bottom = 0;
        };
        padding = true;
        sort = ["level" "added"];
        icons = {
          error = " ";
          warn = " ";
          info = " ";
          debug = " ";
          trace = " ";
        };
      };
    };
  };
}
