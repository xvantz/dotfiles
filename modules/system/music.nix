{config, ...}: {
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

  systemd.tmpfiles.rules = [
    "d /var/lib/slskd/downloads 0750 slskd slskd - -"
    "d /var/lib/slskd/incomplete 0750 slskd slskd - -"
  ];
  users.users.xvantz.extraGroups = ["navidrome-collector"];
}
