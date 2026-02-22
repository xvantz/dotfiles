{...}: {
  services.coolcontrol = {
    enable = true;
    config = {
      fan_addresses = [44 45];
      critical_temp = 92.0;
      fan_curve = [
        {
          temp = 45.0;
          speed = 50;
        }
        {
          temp = 60.0;
          speed = 90;
        }
        {
          temp = 75.0;
          speed = 160;
        }
        {
          temp = 85.0;
          speed = 210;
        }
        {
          temp = 92.0;
          speed = 254;
        }
      ];
    };
  };
}
