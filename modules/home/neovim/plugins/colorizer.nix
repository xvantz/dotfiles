{...}: {
  programs.nixvim.plugins.colorizer = {
    enable = true;
    lazy = [{event = "BufReadPre";}];

    settings = {
      filetypes = ["*" "!lazy" "!netrw" "!toggleterm" "!Prompt"];
      buftypes = [];
      user_commands = true;
      lazy_load = true;

      options = {
        parsers = {
          css = true;
          css_fn = true;
          hex = {
            default = true;
            rrggbbaa = true;
            no_hash = false;
          };
          names = {enable = false;};
          tailwind = {enable = true;};
          sass = {enable = true;};
        };

        display = {
          mode = "background";
          background = {
            bright_fg = "#000000";
            dark_fg = "#ffffff";
          };
          disable_document_color = true;
        };
      };
    };
  };
}
