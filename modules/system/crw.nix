{...}: {
  virtualisation.oci-containers.containers.crw = {
    image = "ghcr.io/us/crw";
    ports = ["127.0.0.1:8889:3000"];
    extraOptions = ["--pull=always"];
  };
}
