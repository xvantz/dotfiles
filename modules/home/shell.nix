{...}: {
  programs.zsh = {
    enable = true;
    # autoSuggestions.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ls = "eza --icons";
      cd = "z";
      rebuild = "sudo nixos-rebuild switch --flake ~/.dotfiles#nixos";
    };
    initContent = ''
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
    '';
  };

  programs.zoxide.enableZshIntegration = true;

  home.sessionVariables = {
    XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = "24";
    COLOR_SCHEME = "prefer-dark";
  };
}
