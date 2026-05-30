{...}: {
  programs.nixvim.plugins.tiny-inline-diagnostic = {
    enable = true;

    settings = {
      preset = "modern";
      transparent_bg = false;
      transparent_cursorline = true;

      options = {
        show_source = {
          enabled = true;
          if_many = true;
        };

        show_code = true;

        use_icons_from_diagnostic = true;
        set_arrow_to_diag_color = true;
        throttle = 20;

        show_all_diags_on_cursorline = true;

        show_related = {
          enabled = true;
          max_count = 3;
        };

        enable_on_insert = false;

        multilines = {
          enabled = true;
          always_show = false;
          trim_whitespaces = true;
        };

        overflow = {
          mode = "wrap";
        };
      };
    };
  };
}
