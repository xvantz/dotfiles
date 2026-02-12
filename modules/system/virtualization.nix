{...}: {
  virtualisation.docker.enable = true;

  virtualisation.docker.autoPrune.enable = true;

  users.users.xvantz.extraGroups = ["docker"];

  boot.initrd.kernelModules = ["vfio_pci" "vfio" "vfio_iommu_type1"];

  boot.extraModprobeConfig = ''
    options vfio-pci ids=10de:25a0
    options vfio-pci ids=10de:2291
  '';

  boot.blacklistedKernelModules = ["nvidia" "nouveau"];
}
