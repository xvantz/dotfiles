{...}: {
  services.coolcontrol = {
    enable = true;
    config = {
      fan_addresses = [44 45];
      critical_temp = 85.0;
      fan_curve = [
        {
          temp = 40.0;
          speed = 30;
        }
        {
          temp = 50.0;
          speed = 50;
        }
        {
          temp = 65.0;
          speed = 110;
        }
        {
          temp = 75.0;
          speed = 200;
        }
        {
          temp = 82.0;
          speed = 255;
        }
      ];
    };
  };
}
