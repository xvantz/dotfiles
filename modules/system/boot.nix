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
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = ["acpi_enforce_resources=lax" "pci=noaer" "pcie_aspm=force"];

    kernel.sysctl = {
      "vm.swappiness" = 180;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
      "vm.page-cluster" = 0;
    };
  };
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
    priority = 100;
  };
}
