{ config, pkgs, inputs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
    };
  };
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "hp-wmi" "ec_sys" "it87" "k10temp" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  hardware.enableAllFirmware = true;
  boot.kernelParams = [
    "acpi_enforce_resources=lax"
    "pci=noaer"
  ];

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  networking.dhcpcd.enable = false;
  services.resolved = { 
    enable = true;
    dnssec = "true";
    fallbackDns = [
      "1.1.1.1"
      "1.0.0.1"
    ];
    llmnr = "false";
    dnsovertls = "true";
    extraConfig = ''
      Cache=yes
      Domains=~.
    '';
  };
  networking.nameservers = [ "127.0.0.53" "1.1.1.1" "1.0.0.1" ];
  networking.resolvconf.enable = false;

  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      libva-vdpau-driver
      libvdpau-va-gl
      mesa
      libglvnd
    ];
  };
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50; 
    priority = 100;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];


  # Enable the GNOME Desktop Environment.
  services.desktopManager.gnome.enable = false;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "catppuccin-mocha-mauve";
  };
  services.displayManager.defaultSession = "niri";
  environment.gnome.excludePackages = with pkgs; [
    gnome-terminal gnome-console gedit epiphany geary evince
    totem gnome-music gnome-photos cheese gnome-maps gnome-weather
    gnome-system-monitor gnome-software gnome-logs gnome-calculator
    gnome-characters gnome-contacts gnome-font-viewer gnome-clocks
    gnome-connections gnome-calendar gnome-tour gnome-user-docs
    tali iagno hitori atomix
  ];
  # environment.sessionVariables.XDG_DATA_DIRS = lib.mkForce [ "/run/current-system/sw/share" ];
  environment.variables = {
    "WLR_DRM_DEVICES" = "/dev/dri/card1";
    "WLR_RENDERER_ALLOW_SOFTWARE" = "0";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "grp:caps_toggle";
  };

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    extraConfig.pipewire."92-ldac-rates" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 ];
      };
    };
    wireplumber.extraConfig."11-bluetooth-policy" = {
      "monitor.bluez.properties" = {
      "bluez5.enable-sbc-xq" = true;
      "bluez5.enable-msbc" = true;
      "bluez5.codecs" = [ "ldac" "aptx_hd" "aac" "sbc" ];
      };
    };
  };
  xdg.portal = {
    enable = true;
    config.common.default = [ "gnome" "gtk" ];
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
  };
  services.gnome.at-spi2-core.enable = lib.mkForce false;
  services.gvfs.enable = lib.mkForce false;
  services.gnome.core-shell.enable = lib.mkForce false;
  services.gnome.core-utilities.enable = lib.mkForce false;
  services.gnome.evolution-data-server.enable = lib.mkForce false;
  services.gnome.gnome-online-accounts.enable = lib.mkForce false;
  services.gnome.gnome-keyring.enable = lib.mkForce false;
  programs.dconf.enable = true;
  services.dbus.enable = true;
  services.dbus.implementation = "broker";
  services.thermald.enable = true;
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    charger = {
      governor = "performance";
      turbo = "auto";
    };
    battery = {
      governor = "powersave";
      turbo = "never";
    };
  };
  services.upower.enable = true;
  security.polkit.enable = true;
  programs.coolercontrol.enable = true;
  security.pam.services.hyprlock = {};

  services.power-profiles-daemon.enable = false;
  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.xvantz = {
    isNormalUser = true;
    description = "Ivan R.";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    packages = with pkgs; [
    ];
    shell = pkgs.zsh;
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
	  vim
	  neovim
    git
	  wget
	  curl
    wl-clipboard
    xclip
    waybar
    fuzzel
    mako
    xwayland-satellite
    pciutils
    lm_sensors
    (catppuccin-sddm.override {
      flavor = "mocha";
      accent = "mauve";
      font = "JetBrainsMono Nerd Font";
      fontSize = "12";
     })
    nbfc-linux
    mission-center
    mesa-demos
    vulkan-tools
    gsettings-desktop-schemas
    adwaita-icon-theme
    gtk4
    libadwaita
    hyprlock
    hypridle
    catppuccin-cursors.mochaDark
  ];
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  programs.zsh.enable = true;
  
  programs.niri = {
    enable = true;
    package = pkgs.niri;
  };

  programs.uwsm = {
    enable = true;
    waylandCompositors = {
      niri = {
        prettyName = "Niri";
        binPath = "${pkgs.niri}/bin/niri-session";
      };
    };
  };
  programs.light.enable = true;

  users.defaultUserShell = pkgs.zsh;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.udev.extraRules = ''
    ACTION=="add|change", ATTRS{idVendor}=="342d", ATTRS{idProduct}=="e487", ENV{LIBINPUT_ATTR_KEYBOARD_DEBOUNCE_DELAY}="50ms"
    ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card1", ATTR{device/power_dpm_force_performance_level}="high"
  '';

  nix.settings = {
    substituters = [
      "https://anyrun.cachix.org"
    ];
    trusted-public-keys = [
      "anyrun.cachix.org-1:pqBobmOjI7nKlsUMV25u9QHa9btJK65/C8vnO3p346s="
    ];
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
