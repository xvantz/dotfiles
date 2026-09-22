{ pkgs, ... }:
{
  systemd.services.chrome-headless = {
    description = "Headless Chromium for Hermes browser_exec (CDP)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "xvantz";
      Type = "simple";
      StateDirectory = "chrome-headless";
      ExecStart = "${pkgs.chromium}/bin/chromium "
        + "--headless=new --no-first-run --no-default-browser-check "
        + "--disable-dev-shm-usage --disable-gpu "
        + "--remote-debugging-address=127.0.0.1 --remote-debugging-port=9222 "
        + "--remote-allow-origins=* "
        + "--user-data-dir=/var/lib/chrome-headless "
        + "about:blank";
      Restart = "always";
      RestartSec = "3";
    };
  };
}
