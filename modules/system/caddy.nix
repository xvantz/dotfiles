{...}: {
  services.caddy = {
    enable = true;
    virtualHosts."git.xvantz.me" = {
      extraConfig = ''
        tls internal
        reverse_proxy http://127.0.0.1:2000
      '';
    };
  };
}
