{...}: {
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      theme = "Catppuccin Mocha";
      font-size = 12;
      window-decoration = false;
      confirm-close-surface = false;
    };
  };
}
