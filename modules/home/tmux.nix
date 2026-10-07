{pkgs, ...}: {
  programs.tmux = {
    enable = true;
    clock24 = true;
    historyLimit = 50000;
    baseIndex = 1;
    keyMode = "vi";
    prefix = "C-a";
    mouse = true;
    escapeTime = 0;

    extraConfig = ''
      set -g status-position top
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      set -g renumber-windows on
      set -g focus-events on
      set -g status-interval 1
      set -g extended-keys
      set -s set-clipboard on

      bind -r h select-pane -L
      bind -r j select-pane -D
      bind -r k select-pane -U
      bind -r l select-pane -R

      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      bind c new-window -c "#{pane_current_path}"
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind C command-prompt -p "Name of new window: " "new-window -n '%%'"

      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9
      bind -n M-0 select-window -l

      bind -T copy-mode-vi y send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
      bind -T copy-mode-vi Y send -X copy-pipe-and-cancel "${pkgs.wl-clipboard}/bin/wl-copy"
      bind p run-shell "${pkgs.wl-clipboard}/bin/wl-paste -n | tmux load-buffer - && tmux paste-buffer"

      bind r source-file ~/.config/tmux/tmux.conf \; display "✓ Config reloaded!"

      set -g status-right-length 100
      set -g status-left-length 100
      set -g status-left ""
    '';

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = catppuccin;
        extraConfig = ''
          set -g @catppuccin_flavor 'mocha'
          set -g @catppuccin_window_status_style "rounded"
        '';
      }
      {
        plugin = sensible;
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
        '';
      }
    ];
  };

  # Resurrect save dir (old resurrect writes to ~/.tmux, not XDG).
  # Declarative keep so the dir always exists after home switch.
  home.file.".tmux/resurrect/.keep".text = "keep";

  # User-level keepalive: starts AFTER home files (tmux.conf + plugins)
  # are in place, with a real user env (PATH/HOME). This replaces the
  # old system driftty-tmux-keepalive which started at boot with a bare
  # env -> plugin scripts failed with 127 -> default theme, no restore.
  systemd.user.services.tmux-keepalive = {
    Unit = {
      Description = "keep tmux default session alive (after tmux config)";
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Full PATH: plugin scripts (#!/usr/bin/env bash) resolve interpreters
      # via the SERVER env. Bare systemd PATH -> 127 for every plugin.
      Environment = [
        "TERM=xterm-256color"
        "PATH=/run/current-system/sw/bin:/run/wrappers/bin:%h/.nix-profile/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin"
      ];
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %t/tmux-1000";
      # NOTE: no -A flag here. -A turns into attach when the session
      # exists, and attach needs a tty -> "open terminal failed" under
      # systemd. has-session check keeps exit code clean both ways.
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.tmux}/bin/tmux -S %t/tmux-1000/default has-session -t default 2>/dev/null || exec ${pkgs.tmux}/bin/tmux -S %t/tmux-1000/default new-session -d -s default -c %h'";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
