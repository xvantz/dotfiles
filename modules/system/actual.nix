{...}: {
  systemd.tmpfiles.rules = [
    "d /var/lib/actual 0755 root root -"
  ];

  virtualisation.oci-containers.containers.actual = {
    image = "docker.io/actualbudget/actual-server:latest";
    ports = ["127.0.0.1:5006:5006"];
    volumes = ["/var/lib/actual:/data"];
    extraOptions = ["--pull=always"];
  };
}
