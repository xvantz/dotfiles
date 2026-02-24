{...}: {
  services.redis.servers."main" = {
    enable = true;
    port = 6379;
  };
}
