{pkgs, ...}: {
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
      };
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
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
      "kernel.sysrq" = 1;
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
}
