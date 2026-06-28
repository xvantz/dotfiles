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
      allowedTCPPorts = [53 80 443 22005 22006 9000];
      allowedUDPPorts = [53 22005 22006];
    };
  };
}
