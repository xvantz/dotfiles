# HP Victus 16-e1xxx charge limiter.
#
# Why: the stock firmware charges to 17.5 V = 4.38 V/cell. The cells are
# 3.85 V-nominal Li-HV (15.4 V / 4), so that is in spec, but it is the ceiling
# where electrolyte oxidation and gas generation peak - the reason the previous
# pack swelled. Capping near 4.03 V/cell is the BU-808 "Long Life" point: every
# 0.10 V below the ceiling roughly doubles cycle life.
#
# Protocol: this board exposes GBCO/SBCO (HP WMI command 0x2B) for charge-mode
# control through EC register BDVO, read out of its own DSDT with iasl. The
# GBCC/SBCC pair (0x1F, MBDC) is a different mechanism on a different register
# and refused the writes this module first tried - see the script header.
#
# Measured on this pack while tuning: 74% rests at 16.06 V (4.015 V/cell) and
# 82% at 16.45 V (4.114 V/cell), so 75% ~ 4.03 V/cell. The gauge tracked the
# voltage linearly across that range and is driven as the primary criterion;
# voltage is only a backstop.
#
# Two units:
#   hp-charge-limit.service/.timer  one control pass every 5 min
#   hp-charge-limit-shutdown        inhibit before poweroff, so a powered-off
#                                   laptop left on the adapter does not charge
#                                   to the ceiling. Whether BDVO survives a
#                                   power-off on this board is unverified.
{ config, lib, pkgs, ... }:

let
  # writeShellScript only guarantees bash. Everything else the script calls
  # (flock from util-linux, dd/date/stat from coreutils, sed, grep, awk) has to
  # be put on PATH explicitly, or it dies as "flock: command not found" at the
  # first flock in acquire_lock and the unit fails on every timer tick.
  scriptBins = with pkgs; [ util-linux coreutils gnused gnugrep gawk ];
  script = pkgs.writeShellScript "hp-charge-limit" (
    ''export PATH="${lib.makeBinPath scriptBins}:$PATH"'' + "\n"
    + builtins.readFile ./hp-charge-limit.sh
  );
in
{
  boot.kernelModules = [ "acpi_call" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];

  # Not wantedBy multi-user.target: the timer is the driver. Starting it during
  # activation would fail the whole switch if acpi_call is not up yet, and any
  # failure of a control pass is not worth blocking a rebuild over.
  systemd.services.hp-charge-limit = {
    description = "HP battery charge limiter (cap near 4.03 V/cell)";
    after = [ "systemd-modules-load.service" ];
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 30;
      StateDirectory = "hp-charge-limit";
      ExecStart = "${script} tick";
    };
  };

  systemd.timers.hp-charge-limit = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "3min";
      OnUnitActiveSec = "5min";
      AccuracySec = "30s";
    };
  };

  # Runs before poweroff/reboot. DefaultDependencies=no so it is not torn down
  # by the normal shutdown ordering before it gets to write the EC.
  systemd.services.hp-charge-limit-shutdown = {
    description = "Stop HP battery charging before shutdown";
    wantedBy = [ "shutdown.target" ];
    before = [ "shutdown.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      TimeoutStartSec = 30;
      StateDirectory = "hp-charge-limit";
      ExecStart = "${script} shutdown";
    };
  };
}
