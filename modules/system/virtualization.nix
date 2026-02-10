{...}: {
  virtualisation.docker.enable = true;
  users.users.xvantz.extraGroups = ["docker"];
}
