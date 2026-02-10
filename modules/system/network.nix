{...}: {
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;

    useDHCP = false;
    dhcpcd.enable = false;
    resolvconf.enable = false;

    nameservers = [
      "127.0.0.53"
      "1.1.1.1"
      "1.0.0.1"
      "9.9.9.9"
    ];
  };

  services.resolved = {
    enable = true;
    dnssec = "true";
    dnsovertls = "true";
    nameservers = [
      "1.1.1.1#cloudflare-dns.com"
      "9.9.9.9#dns.quad9.net"
    ];
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
