{...}: {
  programs.nixvim.plugins.mini-ai = {
    enable = true;

    settings = {
      n_lines = 500;
    };
  };
}
