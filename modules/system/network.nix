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

    # MSS clamp под реальный path MTU: чинит TCP на битых path
    # (PMTU blackhole), где большие сегменты дохнут молча.
    # Замеренный потолок path - 1400 байт, MSS 1360 = 1400 - 40
    # на IP+TCP заголовки. Только уменьшает, поэтому безопасно
    # на любой сети. Адаптивность под другие сети дает
    # tcp_mtu_probing ниже. Аналог галки mtu_fix=1 в OpenWrt.
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

  # Самолечение TCP при PMTU blackhole: ядро само щупает
  # меньший MSS при затыке. 1 = включать при детекте blackhole.
  # См. docs.kernel.org, networking/ip-sysctl, tcp_mtu_probing.
  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;
}
