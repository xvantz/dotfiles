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
      # Tuned 2026-09-23 (variant B): slower rise, faster decay.
      # Up 6 PWM/s, down 8 PWM/s, hold 3s / 1.5C on decreases.
      smoothing = {
        ema_alpha = 0.3;
        max_step_up = 6;
        max_step_down = 8;
        min_step = 2;
        hysteresis_temp = 1.5;
        hysteresis_delay_s = 3;
        only_downward = true;
      };
    };
  };
}
