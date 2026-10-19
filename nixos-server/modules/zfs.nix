{ ... }:

{
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.extraPools = [ "storage" ];
  boot.zfs.forceImportRoot = false;

  # same host id as alma-server so the existing pool imports without forcing
  networking.hostId = "70b9b589";
}
