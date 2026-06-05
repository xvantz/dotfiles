{...}: {
  services.forgejo = {
    enable = true;
    database.type = "postgres";
    settings.server = {
      DOMAIN = "git.xvantz.me";
      ROOT_URL = "https://git.xvantz.me";
      HTTP_PORT = 2000;
    };
  };
}
