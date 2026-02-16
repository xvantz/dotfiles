{...}: {
  boot.extraModprobeConfig = ''
    options mt7921e disable_aspm=1
  '';
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      insertNameservers = ["9.9.9.9" "1.1.1.1"];
    };

    enableIPv6 = false;

    useDHCP = false;
    dhcpcd.enable = false;
    resolvconf.enable = false;

    nameservers = [
      "1.1.1.1#cloudflare-dns.com"
      "9.9.9.9#dns.quad9.net"
    ];
  };

  services.resolved = {
    enable = true;
    dnssec = "false";
    dnsovertls = "true";
    fallbackDns = [
      "1.0.0.1#cloudflare-dns.com"
      "149.112.112.112#dns.quad9.net"
    ];
    llmnr = "false";
    extraConfig = ''
      Cache=yes
      Domains=~.
    '';
  };
}
