{...}: {
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      wifi.powersave = false;
      insertNameservers = ["127.0.0.1" "9.9.9.9" "1.1.1.1"];
    };

    enableIPv6 = false;

    useDHCP = false;
    dhcpcd.enable = false;
    resolvconf.enable = false;

    firewall = {
      enable = true;
      allowedTCPPorts = [53 22005 22006 9000];
      allowedUDPPorts = [53 22005 22006];
    };
  };

  services.resolved = {
    enable = true;
    extraConfig = ''
      DNS=127.0.0.1
      DNSStubListener=no
    '';
    settings = {
      Resolve = {
        Domains = "~.";
        LLMNR = "false";
      };
    };
  };
}
