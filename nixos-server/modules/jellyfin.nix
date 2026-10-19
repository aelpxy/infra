{ pkgs, ... }:

{
  systemd.tmpfiles.rules = [
    "d /srv/jellyfin/config 0750 root root -"
    "d /srv/jellyfin/cache 0750 root root -"
  ];

  virtualisation.oci-containers.containers.jellyfin = {
    image = "docker.io/jellyfin/jellyfin:10";
    ports = [ "127.0.0.1:8096:8096" ];
    volumes = [
      "/srv/jellyfin/config:/config"
      "/srv/jellyfin/cache:/cache"
      "/storage/media:/media:ro"
    ];
    extraOptions = [
      "--network=jellyfin"
      "--device=/dev/dri/renderD128"
    ];
  };

  systemd.services.jellyfin-network = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = "${pkgs.podman}/bin/podman network create --ignore jellyfin";
  };

  systemd.services.podman-jellyfin = {
    requires = [ "jellyfin-network.service" ];
    after = [ "jellyfin-network.service" ];
  };
}
