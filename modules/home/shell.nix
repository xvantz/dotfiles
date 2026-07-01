{...}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;
    shellAliases = {
      ls = "eza --icons -la";
      cd = "z";
      update = "nh os switch";
      update-home = "nh home switch";
      ps = "procs";
      pack = "ouch compress";
      unpack = "ouch decompress";
      cat = "bat --theme=\"Catppuccin Mocha\"";
      hermes = "sudo podman exec -it --user 1000:100 hermes-agent /data/current-package/bin/hermes";
    };
    initContent = ''
      eval "$(starship init zsh)"
      eval "$(zoxide init zsh)"
      if [[ -z "$TMUX" ]] && [ "$SSH_CONNECTION" = "" ]; then
        tmux attach-session -t default || tmux new-session -s default
      fi
    '';
  };

  programs.zoxide.enableZshIntegration = true;

  home.sessionVariables = {
    XCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    XCURSOR_SIZE = "24";
    HYPRCURSOR_THEME = "catppuccin-mocha-dark-cursors";
    HYPRCURSOR_SIZE = "24";
    COLOR_SCHEME = "prefer-dark";
    EDITOR = "nvim";
    VISUAL = "nvim";
    QT_QPA_PLATFORMTHEME = "xdgdesktopportal";
    QT_QPA_PLATFORM = "wayland;xcb";
    NH_NOM = "1";
  };
}
