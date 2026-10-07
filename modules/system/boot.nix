{pkgs, ...}: {
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub.enable = false;
      systemd-boot.enable = false;
      limine = {
        enable = true;
        efiSupport = true;
        maxGenerations = 7;
        style = {
          backdrop = "1a1b26";
          interface = {
            brandingColor = "bb9af7";
            helpColor = "7aa2f7";
            helpColorBright = "8db0ff";
          };
          graphicalTerminal = {
            font.scale = "2x2";
            palette = "15161e;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;a9b1d6";
            brightPalette = "414868;ff899d;9fe044;faba4a;8db0ff;c7a9ff;a4daff;c0caf5";
          };
        };
        # Tokyo Night (night variant), source: github.com/Bukutsu/tokyo-night-limine (MIT)
        # term colors have no structured option, passed raw.
        extraConfig = ''
          term_background: ff1a1b26
          term_foreground: c0caf5
          term_background_bright: ff24283b
          term_foreground_bright: c0caf5
        '';
      };
      timeout = 5;
    };
    initrd.kernelModules = ["amdgpu"];
    kernelModules = ["hp-wmi" "ec_sys" "it87" "k10temp"];
    extraModprobeConfig = ''
      options ec_sys write_support=1
    '';
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [
      "acpi_enforce_resources=lax"
      "pci=noaer"
      "pcie_aspm=force"
      "usbcore.autosuspend=-1"
      "usbcore.quirks=342d:e487:g"
      "amdgpu.gpu_recovery=1"
      "amdgpu.runpm=0"
      "amdgpu.dcdebugmask=0x10"
      "amdgpu.dpm=1"
    ];

    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
      "kernel.sysrq" = 1;
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };
}
