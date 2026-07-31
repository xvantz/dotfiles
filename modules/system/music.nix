{
  config,
  pkgs,
  ...
}: {
  sops.secrets.slskd_env = {
    owner = "xvantz";
  };
  sops.secrets.nvc_env = {
    owner = "xvantz";
  };

  services = {
    navidrome = {
      enable = true;

      settings = {
        MusicFolder = "/srv/music";
        Address = "0.0.0.0";
        Port = 4533;

        EnableSharing = true;
        ScanSchedule = "@every 1m";
      };
    };

    slskd = {
      enable = true;
      environmentFile = config.sops.secrets.slskd_env.path;
      openFirewall = true;
      settings = {
        directories.downloads = "/var/lib/slskd/downloads";
        directories.incomplete = "/var/lib/slskd/incomplete";
        shares.directories = ["/srv/music"];
        web.authentication.api_keys.bot = {
          key = "nvc-collector-api-key-2026";
          role = "readwrite";
        };
      };
    };

    navidrome-collector = {
      enable = true;
      environmentFile = config.sops.secrets.nvc_env.path;
    };
  };

  systemd.services.slskd = {
    after = ["sops-install-secrets.service"];
    wants = ["sops-install-secrets.service"];
  };

  systemd.services.navidrome-collector = {
    after = ["sops-install-secrets.service" "slskd.service"];
    wants = ["sops-install-secrets.service" "slskd.service"];
    serviceConfig = {
      ExecStartPre = [
        "${pkgs.bash}/bin/bash -c 'for i in {1..30}; do exec 3<>/dev/tcp/127.0.0.1/5030 2>/dev/null && exec 3<&- && exit 0; sleep 1; done; exit 1'"
      ];
    };
  };

  systemd.tmpfiles.rules = [
    "d /srv/slskd/downloads 0750 slskd slskd - -"
    "d /var/lib/slskd/downloads 0750 slskd slskd - -"
    "d /var/lib/slskd/incomplete 0750 slskd slskd - -"
  ];
  users.users.xvantz.extraGroups = ["navidrome-collector"];
  users.groups.navidrome.members = ["navidrome-collector"];
}
