{...}: {
  programs.starship = {
    enable = true;
    settings = {
      format = "$all";

      directory = {
        truncation_length = 3;
        fish_style_pwd_dir_length = 1;
      };

      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[➜](bold red)";
      };

      git_branch = {
        symbol = " ";
      };

      nix_shell = {
        symbol = " ";
        format = "via [$symbol($name)]($style) ";
      };
    };
  };
}
