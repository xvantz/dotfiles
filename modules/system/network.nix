{...}: {
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      insertNameservers = ["127.0.0.1" "9.9.9.9" "1.1.1.1" "2606:4700:4700::1111" "2620:fe::fe"];
    };

    enableIPv6 = true;

    useDHCP = false;
    dhcpcd.enable = false;
    resolvconf.enable = false;

    firewall = {
      enable = true;
      allowedTCPPorts = [22 53 80 443 22005 22006 9000];
      allowedUDPPorts = [53 22005 22006];
    };

    nftables.enable = true;
    nftables.tables.mss-clamp = {
      family = "inet";
      content = ''
        chain prerouting {
          type filter hook prerouting priority -150; policy accept;
          tcp flags syn tcp option maxseg size set 1360
        }
        chain postrouting {
          type filter hook postrouting priority -150; policy accept;
          tcp flags syn tcp option maxseg size set 1360
        }
      '';
    };
  };

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;
}
