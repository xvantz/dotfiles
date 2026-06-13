{...}: {
  programs.ghostty = {
    enable = true;
    settings = {
      font-family = "JetBrainsMono Nerd Font";
      theme = "TokyoNight";
      font-size = 12;
      window-decoration = false;
      confirm-close-surface = false;
      background-blur = 1;
      background-opacity = 0.8;
    };
  };
}
