{...}: {
  programs.starship = {
    enable = true;
    settings = {
      format = "$all";

      # Default is 30ms: too tight on a cold page cache, and NixOS profiles
      # are symlink chains. Panes restored in a burst (resurrect) each trip it
      # with "starship::context: Scanning current directory timed out".
      scan_timeout = 100;

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
