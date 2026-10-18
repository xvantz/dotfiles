{lib, ...}: {
  virtualisation.oci-containers.containers.dozzle = {
    image = "docker.io/amir20/dozzle:latest";
    ports = ["127.0.0.1:9999:8080"];
    volumes = ["/run/podman/podman.sock:/var/run/docker.sock:ro"];
    extraOptions = ["--pull=missing"];
  };

  # Local log viewer: must not gate multi-user.target (+3.5s pull on the
  # graphical critical path) nor wait for external network (localhost
  # bind + podman socket only). Starts in background, updates by hand
  # via podman pull.
  systemd.services.podman-dozzle = {
    after = lib.mkForce ["multi-user.target" "podman.service"];
    wants = lib.mkForce [];
  };
}
