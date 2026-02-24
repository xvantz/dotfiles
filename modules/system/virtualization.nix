{
  pkgs,
  config,
  selfPath,
  ...
}: {
  virtualisation.docker.enable = true;

  virtualisation.docker.autoPrune.enable = true;

  users.users.xvantz.extraGroups = ["docker" "libvirtd" "kvm"];

  boot.initrd.kernelModules = ["vfio_pci" "vfio" "vfio_iommu_type1"];
  boot.kernelParams = ["amd_iommu=on" "iommu=pt" "vfio-pci.ids=10de:25a0,10de:2291"];
  boot.extraModulePackages = [config.boot.kernelPackages.kvmfr];
  boot.kernelModules = ["kvmfr"];
  boot.extraModprobeConfig = ''
    options kvmfr static_size_mb=64
    options vfio-pci ids=10de:25a0,10de:2291
  '';
  boot.blacklistedKernelModules = [
    "nvidia"
    "nouveau"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nova_core"
  ];
  boot.initrd.preDeviceCommands = ''
    DEVS="0000:01:00.0 0000:01:00.1"
    for DEV in $DEVS; do
      echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
    done
  '';

  systemd.services.kvmfr-options = {
    description = "Set permissions for /dev/kvmfr0";
    after = ["systemd-modules-load.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "kvmfr-permissions" ''
        for i in {1..10}; do
          if [ -e /dev/kvmfr0 ]; then
            ${pkgs.coreutils}/bin/chown xvantz:kvm /dev/kvmfr0
            ${pkgs.coreutils}/bin/chmod 0660 /dev/kvmfr0
            exit 0
          fi
          sleep 0.5
        done
        echo "Device /dev/kvmfr0 not found after waiting"
        exit 1
      '';
      RemainAfterExit = true;
    };
  };

  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;
      verbatimConfig = ''
        cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/rtc",
            "/dev/hpet", "/dev/kvmfr0"
        ]
      '';
    };
  };

  environment.systemPackages = with pkgs; [
    virt-manager
    looking-glass-client
    virtio-win
  ];

  systemd.tmpfiles.rules = [
    "d /var/lib/libvirt/images 0755 qemu-libvirtd qemu-libvirtd - -"
    "C+ /var/lib/libvirt/images/ssdt1.dat 0644 qemu-libvirtd qemu-libvirtd - ${selfPath}/config/virtual/ssdt1.dat"
  ];

  system.activationScripts.createWin11Disk = {
    text = ''
      DISK_PATH="/var/lib/libvirt/images/win11.qcow2"
      if [ ! -f "$DISK_PATH" ]; then
        mkdir -p /var/lib/libvirt/images
        ${pkgs.qemu_kvm}/bin/qemu-img create -f qcow2 "$DISK_PATH" 100G
        chown qemu-libvirtd:qemu-libvirtd "$DISK_PATH"
        chmod 644 "$DISK_PATH"
      fi
    '';
  };

  environment.etc."looking-glass-client.ini".text = ''
    [win]
    showFPS=yes

    [input]
    escapeKey=27

    [spice]
    alwaysShowCursor=yes
  '';
  environment.etc."libvirt/qemu/win11.xml".text = ''
    <domain type='kvm' xmlns:qemu='http://libvirt.org/schemas/domain/qemu/1.0'>
      <name>win11</name>
        <uuid>87654321-4321-4321-4321-210987654321</uuid>
        <metadata>
          <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
            <libosinfo:os id="http://microsoft.com/win/11"/>
          </libosinfo:libosinfo>
        </metadata>
        <memory unit='KiB'>16384000</memory>
        <currentMemory unit='KiB'>16384000</currentMemory>
        <vcpu placement='static'>8</vcpu>
        <os firmware="efi">
          <type arch="x86_64" machine="q35">hvm</type>
        </os>
        <features>
          <acpi/>
          <apic/>
          <hyperv mode='custom'>
            <relaxed state='on'/>
            <vapic state='on'/>
            <spinlocks state='on' retries='8191'/>
            <vpindex state='on'/>
            <runtime state='on'/>
            <synic state='on'/>
            <stimer state='on'/>
            <reset state='on'/>
            <vendor_id state='on' value='GenuineIntel'/>
            <frequencies state='on'/>
            <tlbflush state='on'/>
            <evmcs state='off'/>
          </hyperv>
          <kvm>
            <hidden state='on'/>
          </kvm>
          <vmport state='off'/>
          <smm state='on'/>
          <ioapic driver='kvm'/>
        </features>
        <cpu mode='host-passthrough' check='none' migratable='on'>
          <topology sockets='1' dies='1' clusters='1' cores='4' threads='2'/>
          <feature policy='require' name='topoext'/>
          <feature policy='disable' name='hypervisor'/>
        </cpu>
        <clock offset='localtime'>
          <timer name='rtc' tickpolicy='catchup'/>
          <timer name='pit' tickpolicy='delay'/>
          <timer name='hpet' present='no'/>
          <timer name='hypervclock' present='yes'/>
        </clock>
        <on_poweroff>destroy</on_poweroff>
        <on_reboot>restart</on_reboot>
        <on_crash>destroy</on_crash>
        <pm>
          <suspend-to-mem enabled='no'/>
          <suspend-to-disk enabled='no'/>
        </pm>
        <devices>
          <emulator>${pkgs.qemu_kvm}/bin/qemu-system-x86_64</emulator>
            <disk type='file' device='disk'>
              <driver name='qemu' type='qcow2' discard='unmap'/>
              <source file='/var/lib/libvirt/images/win11.qcow2'/>
              <target dev='vda' bus='virtio'/>
              <boot order='1'/>
              <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
            </disk>
            <disk type='file' device='cdrom'>
              <driver name='qemu' type='raw'/>
              <source file='/var/lib/libvirt/images/virtio-win.iso'/>
              <target dev='sda' bus='sata'/>
              <readonly/>
              <boot order='2'/>
              <address type='drive' controller='0' bus='0' target='0' unit='0'/>
            </disk>
            <disk type='file' device='cdrom'>
              <driver name='qemu' type='raw'/>
              <source file='/var/lib/libvirt/images/win11_ltsc.iso'/>
              <target dev='sdb' bus='sata'/>
              <readonly/>
              <boot order='3'/>
              <address type='drive' controller='0' bus='0' target='0' unit='1'/>
            </disk>
            <controller type='usb' index='0' model='qemu-xhci' ports='15'>
              <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
            </controller>
            <controller type='pci' index='0' model='pcie-root'/>
            <controller type='pci' index='1' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='1' port='0x10'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
            </controller>
            <controller type='pci' index='2' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='2' port='0x11'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
            </controller>
            <controller type='pci' index='3' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='3' port='0x12'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
            </controller>
            <controller type='pci' index='4' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='4' port='0x13'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
            </controller>
            <controller type='pci' index='5' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='5' port='0x14'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
            </controller>
            <controller type='pci' index='6' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='6' port='0x15'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
            </controller>
            <controller type='pci' index='7' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='7' port='0x16'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
            </controller>
            <controller type='pci' index='8' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='8' port='0x17'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
            </controller>
            <controller type='pci' index='9' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='9' port='0x18'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>
            </controller>
            <controller type='pci' index='10' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='10' port='0x19'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>
            </controller>
            <controller type='pci' index='11' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='11' port='0x1a'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>
            </controller>
            <controller type='pci' index='12' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='12' port='0x1b'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>
            </controller>
            <controller type='pci' index='13' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='13' port='0x1c'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>
            </controller>
            <controller type='pci' index='14' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='14' port='0x1d'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>
            </controller>
            <controller type='pci' index='15' model='pcie-root-port'>
              <model name='pcie-root-port'/>
              <target chassis='15' port='0x1e'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x6'/>
            </controller>
            <controller type='pci' index='16' model='pcie-to-pci-bridge'>
              <model name='pcie-pci-bridge'/>
              <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
            </controller>
            <controller type='sata' index='0'>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
            </controller>
            <controller type='virtio-serial' index='0'>
              <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
            </controller>
            <interface type="network">
              <source network="default"/>
              <mac address="52:54:00:9b:cf:43"/>
              <model type="e1000e"/>
            </interface>
            <serial type='pty'>
              <target type='isa-serial' port='0'>
                <model name='isa-serial'/>
              </target>
            </serial>
            <console type='pty'>
              <target type='serial' port='0'/>
            </console>
            <channel type='spicevmc'>
              <target type='virtio' name='com.redhat.spice.0'/>
              <address type='virtio-serial' controller='0' bus='0' port='1'/>
            </channel>
            <input type='tablet' bus='usb'>
              <address type='usb' bus='0' port='2'/>
            </input>
            <input type='keyboard' bus='ps2'/>
            <input type='mouse' bus='ps2'/>
            <tpm model='tpm-crb'>
              <backend type='emulator' version='2.0'/>
            </tpm>
            <graphics type='spice' autoport='yes'>
              <listen type='address'/>
              <image compression='off'/>
            </graphics>
            <video>
              <model type='cirrus' vram='16384' heads='1' primary='yes'/>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x01' function='0x0'/>
            </video>
            <sound model='ich9'>
              <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
            </sound>
            <audio id='1' type='spice'/>
            <hostdev mode='subsystem' type='pci' managed='yes'>
              <source>
                <address domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
              </source>
              <rom bar='off'/>
              <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0' multifunction='on'/>
            </hostdev>
            <hostdev mode='subsystem' type='pci' managed='yes'>
              <source>
                <address domain='0x0000' bus='0x01' slot='0x00' function='0x1'/>
              </source>
              <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x1'/>
            </hostdev>
            <redirdev bus='usb' type='spicevmc'>
              <address type='usb' bus='0' port='3'/>
            </redirdev>
            <redirdev bus='usb' type='spicevmc'>
              <address type='usb' bus='0' port='4'/>
            </redirdev>
            <watchdog model='itco' action='reset'/>
            <memballoon model='virtio'>
              <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
            </memballoon>
          </devices>

      <qemu:commandline>
        <qemu:arg value='-fw_cfg'/><qemu:arg value='name=opt/ovmf/X-PciMmio64Mb,string=65536'/>
        <qemu:arg value='-acpitable'/><qemu:arg value='file=/var/lib/libvirt/images/ssdt1.dat'/>
        <qemu:arg value="-device"/>
        <qemu:arg value="{'driver':'ivshmem-plain','id':'shmem0','memdev':'looking-glass'}"/>
        <qemu:arg value="-object"/>
        <qemu:arg value="{'qom-type':'memory-backend-file','id':'looking-glass','mem-path':'/dev/kvmfr0','size':67108864,'share':true}"/>
      </qemu:commandline>
    </domain>
  '';

  systemd.services.libvirt-sync-win11 = {
    description = "Sync Windows 11 VM definition";
    after = ["libvirtd.service" "libvirtd.socket"];
    requires = ["libvirtd.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
      ExecStart = "${pkgs.libvirt}/bin/virsh define /etc/libvirt/qemu/win11.xml";
      RemainAfterExit = true;
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };
}
