{pkgs, config, ...}:
let
  zsh = "${config.programs.zsh.package}/bin/zsh";
  tmux = "${pkgs.tmux}/bin/tmux";

  # "The system's own PATH": env -i drops everything inherited (systemd,
  # driftty, container), and the login shell rebuilds PATH from
  # /etc/profile + /etc/set-environment. -i must NOT be used: a plugin
  # banner in .zshrc lands in stdout and turns PATH into garbage (proven).
  # Verified on the host: matches the terminal login shell's PATH exactly.
  probeScript = pkgs.writeShellScript "tmux-path-probe.sh" ''
    exec ${pkgs.coreutils}/bin/env -i \
      HOME="$HOME" USER="$USER" LOGNAME="$USER" TERM=dumb SHELL=${zsh} \
      ${zsh} -lc 'print -r -- $PATH'
  '';

  # package wrapper: home.packages cannot merge a bare file, it needs $out/bin/*
  pathProbe = pkgs.runCommandLocal "tmux-path-probe" { } ''
    install -Dm755 ${probeScript} $out/bin/tmux-path-probe
  '';

  # A broken or empty capture must not produce an empty PATH: validate, then fall back.
  derivePath = ''
    derived="$(${pathProbe}/bin/tmux-path-probe 2>/dev/null)" || derived=""
    if [ -n "$derived" ] && [ "$(printf '%s' "$derived" | wc -l)" -eq 0 ] \
       && printf '%s' "$derived" | grep -q '/run/current-system/sw/bin'; then
      PATH="$derived"
    else
      PATH="/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin"
    fi
    export PATH
  '';

  # How tmux starts a pane (default-command). Without it a pane inherits the
  # client's env: driftty drags in its home-last PATH and zsh -l does not
  # clean that up. Applies to every pane spawned without an explicit command
  # (spawn.c: argc == 0 && !RESPAWN) - verified for new-session/new-window/
  # split-window/respawn-pane.
  paneShell = pkgs.writeShellScript "tmux-pane-shell" ''
    set -u
    ${derivePath}
    exec ${zsh} -l
  '';

  # Session owner and supervisor. The main process must live forever: if the
  # script exits, systemd deactivates the unit and kills the whole cgroup
  # with the server and its panes (tmux-spawn scopes are children of it).
  supervisor = pkgs.writeShellScript "tmux-supervisor" ''
    set -u
    export TMUX_TMPDIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    ${derivePath}
    while :; do
      ${tmux} new-session -A -d -s default 2>/dev/null || true
      while ${tmux} list-sessions >/dev/null 2>&1; do sleep 2; done
      sleep 1
    done
  '';
in {
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
      set -g update-environment 'TERM TERM_PROGRAM'
      set -g renumber-windows on
      set -g focus-events on
      set -g status-interval 1
      set -g extended-keys
      set -s set-clipboard on

      # pane env: PATH is built by the system (pathProbe), not by us.
      # default-shell repeats the home-manager value on purpose: tmux needs an
      # explicit source of truth instead of relying on a module default.
      set -g default-shell ${zsh}
      set -g default-command ${paneShell}
      set -g destroy-unattached off

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
          # The server is now supervised by systemd (tmux-server) and can be
          # recreated deliberately or after a crash, so auto-restore is on:
          # session state is durable instead of hanging off a cgroup.
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '5'
        '';
      }
    ];
  };

  # Resurrect save dir (old resurrect writes to ~/.tmux, not XDG).
  # Declarative keep so the dir always exists after home switch.
  home.file.".tmux/resurrect/.keep".text = "keep";

  # Put the probe on PATH: it is also the manual check that tmux sees the same
  # PATH as the login shell. The unit uses it by store path directly.
  home.packages = [ pathProbe ];

  # tmux server: the only owner of the session, everyone else is a client.
  # Driftty and login shells only attach, so their env and their restarts
  # cannot affect the session. Boot start comes from linger for xvantz
  # (modules/system/virtualization.nix).
  # Type=simple is required: the main process holds the cgroup with the
  # server and its panes.
  systemd.user.services.tmux-server = {
    Unit.Description = "tmux server owner and supervisor";
    Service = {
      Type = "simple";
      ExecStart = supervisor;
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
