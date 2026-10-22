{ config, pkgs, ... }:

{
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    device = "nodev";
    configurationLimit = 10;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "nixos-server";
    useDHCP = false;
    interfaces.enp4s0.ipv4.addresses = [
      {
        address = "192.168.0.100";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.0.1";
    nameservers = [ "192.168.0.110" "9.9.9.9" ];
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  time.timeZone = "UTC";

  users.users.aelpxy = {
    isNormalUser = true;
    linger = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbjzV/C2c7hADZWVwaijHaHjomJ/SVaPoGoSpW2HdGr fedora-desktop"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEVAo4dfFYV9PvUBodJ9okErDBlsVd9+BVWP3edixdRH git@aelpxy.dev"
    ];
  };

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "@wheel" ];
    auto-optimise-store = true;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  zramSwap.enable = true;

  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = true;
  hardware.nvidia-container-toolkit.enable = true;

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
    autoPrune.enable = true;
  };
  systemd.user.timers.podman-auto-update.wantedBy = [ "timers.target" ];

  boot.supportedFilesystems = [ "nfs" ];
  fileSystems."/remote-data" = {
    device = "192.168.0.120:/storage/nixos-server";
    fsType = "nfs";
    options = [
      "nfsvers=4.2"
      "x-systemd.automount"
      "noauto"
      "_netdev"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /data 0755 aelpxy users -"
  ];

  environment.systemPackages = with pkgs; [ git ];

  system.stateVersion = "26.05";
}
