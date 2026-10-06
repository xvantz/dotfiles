{ pkgs, config, ... }:
let
  healthQuick = pkgs.writeShellScriptBin "monitoring-quick" ''
    set -eu
    fails=$(systemctl --failed --no-legend 2>/dev/null || true)
    alerts=""
    [ -n "$fails" ] && alerts="FAILED UNITS:\n$fails\n"
    disk=$(df -h / /nix 2>/dev/null | ${pkgs.gawk}/bin/awk 'NR>1 && $5+0 >= 85 {print $6" at "$5}')
    [ -n "$disk" ] && alerts="$alerts DISK >=85%:\n$disk\n"
    for url in http://127.0.0.1:2000 http://127.0.0.1:8888; do
      ${pkgs.curl}/bin/curl -sf --max-time 10 "$url" >/dev/null 2>&1 || alerts="$alerts PROBE DOWN: $url\n"
    done
    if [ -n "$alerts" ]; then
      echo -e "$alerts" | ${pkgs.systemd}/bin/systemd-cat -t monitoring -p warning
      ${quickNotify}/bin/monitoring-notify "$alerts"
    fi
  '';

  quickNotify = pkgs.writeShellScriptBin "monitoring-notify" ''
    msg="$1"
    if [ -r /var/lib/monitoring/telegram.env ]; then
      # shellcheck disable=SC1091
      . /var/lib/monitoring/telegram.env
      if [ -n "''${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "''${TELEGRAM_CHAT_ID:-}" ]; then
        ${pkgs.curl}/bin/curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
          -d "chat_id=$TELEGRAM_CHAT_ID" --data-urlencode "text=[nixos] $msg" >/dev/null || true
      fi
    fi
  '';

  healthDaily = pkgs.writeShellScriptBin "monitoring-daily" ''
    set -eu
    alerts=""
    for dev in $(lsblk -dno NAME,TYPE | ${pkgs.gawk}/bin/awk '$2=="disk"{print "/dev/"$1}'); do
      if ${pkgs.smartmontools}/bin/smartctl -H "$dev" 2>/dev/null | grep -q "FAILED"; then
        alerts="$alerts SMART FAILED: $dev\n"
      fi
    done
    stats_now=$(${pkgs.btrfs-progs}/bin/btrfs device stats / 2>/dev/null || true)
    stats_prev_file=/var/lib/monitoring/btrfs-stats.prev
    if [ -f "$stats_prev_file" ]; then
      while IFS= read -r line; do
        dev=$(echo "$line" | ${pkgs.gawk}/bin/awk -F'[][]' '{print $2}')
        val=$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $NF}')
        prev=$(grep -F "[$dev]" "$stats_prev_file" | grep -F "$(echo "$line" | ${pkgs.gawk}/bin/awk '{print $(NF-1)}')" | ${pkgs.gawk}/bin/awk '{print $NF}' || echo 0)
        if [ "$val" -gt "$prev" ] 2>/dev/null; then
          alerts="$alerts BTRFS ERR GROWTH: $line\n"
        fi
      done <<< "$stats_now"
    fi
    echo "$stats_now" > "$stats_prev_file"
    expiry=$(echo | ${pkgs.openssl}/bin/openssl s_client -connect git.827482.xyz:443 -servername git.827482.xyz 2>/dev/null \
      | ${pkgs.openssl}/bin/openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2 || true)
    if [ -n "$expiry" ]; then
      exp_sec=$(date -d "$expiry" +%s)
      now_sec=$(date +%s)
      if [ $(( (exp_sec - now_sec) / 86400 )) -lt 14 ]; then
        alerts="$alerts CERT EXPIRY <14d: git.827482.xyz ($expiry)\n"
      fi
    fi
    if [ -n "$alerts" ]; then
      echo -e "$alerts" | ${pkgs.systemd}/bin/systemd-cat -t monitoring -p warning
      ${quickNotify}/bin/monitoring-notify "$alerts"
    fi
  '';

  blackboxConfig = pkgs.writeText "blackbox.yml" ''
    modules:
      http_2xx:
        prober: http
        http:
          preferred_ip_protocol: ip4
      tcp_connect:
        prober: tcp
        tcp:
          preferred_ip_protocol: ip4
  '';

  # Telegram chat id for alerts (public user id, not a secret).
  telegramChatId = 857054384;
in
{
  # SMART: scheduled selftests, results go to journal.
  # Alerting is done by the health timers below (no MTA on this box).
  services.smartd = {
    enable = true;
    autodetect = true;
    notifications.systembus-notify.enable = true; # match earlyoom, avoid option conflict
    defaults.monitored = "-a -o on -S on -s (S/../.././02|L/../../6/03)";
  };

  # Btrfs scrub: checksum verification + repair from mirror, monthly.
  # Error counters growth is tracked by monitoring-daily via `btrfs device stats`.
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" ];
  };

  # Metrics layer: exporters -> VictoriaMetrics -> vmalert -> alertmanager -> Telegram.
  # All declarative, no UI pairing, survives fresh installs.
  services.prometheus.exporters.node = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9100;
    enabledCollectors = [ "systemd" "filesystem" "loadavg" "meminfo" "diskstats" "netdev" "cpu" "uname" "time" ];
  };
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9633;
  };
  services.prometheus.exporters.blackbox = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = 9115;
    configFile = blackboxConfig;
  };

  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = "30d";
    prometheusConfig = {
      scrape_configs = [
        {
          job_name = "node";
          static_configs = [{ targets = [ "127.0.0.1:9100" ]; }];
        }
        {
          job_name = "smartctl";
          static_configs = [{ targets = [ "127.0.0.1:9633" ]; }];
        }
        {
          job_name = "blackbox-http";
          metrics_path = "/probe";
          params.module = [ "http_2xx" ];
          static_configs = [{
            targets = [
              "https://git.827482.xyz"
              "http://127.0.0.1:8888"
              "http://127.0.0.1:2000"
            ];
          }];
          relabel_configs = [
            { source_labels = [ "__address__" ]; target_label = "__param_target"; }
            { source_labels = [ "__param_target" ]; target_label = "instance"; }
            { target_label = "__address__"; replacement = "127.0.0.1:9115"; }
          ];
        }
      ];
    };
  };

  services.vmalert.instances.main = {
    enable = true;
    settings = {
      "datasource.url" = "http://127.0.0.1:8428";
      "notifier.url" = [ "http://127.0.0.1:9093" ];
      "evaluationInterval" = "1m";
    };
    rules = {
      groups = [{
        name = "host";
        rules = [
          {
            alert = "InstanceDown";
            expr = ''up{job=~"node|smartctl|blackbox"} == 0'';
            for = "2m";
            annotations.summary = "Exporter {{ $labels.job }} is down";
          }
          {
            alert = "DiskPressure";
            expr = ''node_filesystem_avail_bytes{mountpoint=~"/|/nix"} / node_filesystem_size_bytes{mountpoint=~"/|/nix"} < 0.15'';
            for = "5m";
            annotations.summary = "Disk {{ $labels.mountpoint }} over 85% full";
          }
          {
            alert = "SystemdFailed";
            expr = ''node_systemd_unit_state{state="failed"} == 1'';
            for = "2m";
            annotations.summary = "Unit {{ $labels.name }} failed";
          }
          {
            alert = "ProbeDown";
            expr = ''probe_success == 0'';
            for = "3m";
            annotations.summary = "Probe {{ $labels.instance }} is down";
          }
          {
            alert = "CertExpiring";
            expr = ''(probe_ssl_earliest_cert_expiry - time()) / 86400 < 14'';
            for = "1h";
            annotations.summary = "Cert for {{ $labels.instance }} expires soon";
          }
        ];
      }];
    };
  };

  services.prometheus.alertmanager = {
    enable = true;
    listenAddress = "localhost";
    port = 9093;
    checkConfig = false; # config uses $VAR from environmentFile, invisible to amtool
    environmentFile = config.sops.secrets.monitoring_alertmanager_env.path;
    configuration = {
      route = {
        receiver = "telegram";
        group_wait = "30s";
        group_interval = "5m";
        repeat_interval = "4h";
      };
      receivers = [{
        name = "telegram";
        telegram_configs = [{
          bot_token = "$TELEGRAM_BOT_TOKEN";
          chat_id = telegramChatId;
          send_resolved = true;
        }];
      }];
    };
  };

  # Bot token from @BotFather. Add on host BEFORE rebuilding:
  #   sops secrets.yaml   # add: monitoring_alertmanager_env: TELEGRAM_BOT_TOKEN=<token>
  # Alertmanager runs as systemd DynamicUser (no static uid to chown to),
  # so the env file is world-readable. Single-user box, token is revocable
  # in one click via @BotFather. If this ever becomes multi-user, switch
  # bot_token to bot_token_file with a static service user instead.
  sops.secrets.monitoring_alertmanager_env = {
    owner = "root";
    mode = "0444";
    restartUnits = [ "alertmanager.service" ];
  };
  systemd.services.alertmanager = {
    after = [ "sops-install-secrets.service" ];
    wants = [ "sops-install-secrets.service" ];
  };

  # vmui graphs, tailnet-only like the rest.
  services.caddy.virtualHosts."metrics.827482.xyz" = {
    extraConfig = ''
      @tailnet remote_ip 100.64.0.0/10
      handle @tailnet {
        reverse_proxy http://127.0.0.1:8428
      }
      handle {
        respond "Access requires Tailscale" 403
      }
      tls {
        dns cloudflare {env.CLOUDFLARE_TOKEN}
        resolvers 1.1.1.1
      }
    '';
  };

  # Optional Telegram sink for the timers above (independent of alertmanager).
  # Create once on host:
  #   sudo mkdir -p /var/lib/monitoring
  #   printf 'TELEGRAM_BOT_TOKEN=...\nTELEGRAM_CHAT_ID=...\n' | sudo tee /var/lib/monitoring/telegram.env
  #   sudo chmod 600 /var/lib/monitoring/telegram.env
  # Without it timers only log to journal, nothing fails.
  systemd.tmpfiles.rules = [
    "d /var/lib/monitoring 0755 root root - -"
  ];

  systemd.services.monitoring-quick = {
    description = "Quick health check: failed units, disk usage, local probes";
    path = with pkgs; [ coreutils util-linux gnugrep gawk ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${healthQuick}/bin/monitoring-quick";
    };
  };
  systemd.timers.monitoring-quick = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "15min";
    };
  };

  systemd.services.monitoring-daily = {
    description = "Daily health check: SMART, btrfs errors, cert expiry";
    path = with pkgs; [ coreutils util-linux gnugrep gawk ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${healthDaily}/bin/monitoring-daily";
    };
  };
  systemd.timers.monitoring-daily = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnCalendar = "daily";
    };
  };
}
