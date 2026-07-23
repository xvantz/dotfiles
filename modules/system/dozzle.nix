{ config, pkgs, ... }: {
  virtualisation.oci-containers.containers.dozzle = {
    image = "docker.io/amir20/dozzle:latest";
    ports = [ "127.0.0.1:9999:8080" ];
    volumes = [ "/var/run/docker.sock:/var/run/docker.sock:ro" ];
    extraOptions = [ "--pull=always" ];
  };
}
