{ pkgs, ... }:

let
  secrets = "/var/lib/immich-containers/secrets.env";
in
{
  systemd.tmpfiles.rules = [
    "d /srv/immich/postgres 0700 root root -"
    "d /srv/immich/model-cache 0750 root root -"
  ];

  virtualisation.oci-containers.containers = {
    immich-postgres = {
      image = "ghcr.io/immich-app/postgres:18-vectorchord1.1.1-pgvector0.8.5";
      environment = {
        POSTGRES_USER = "immich";
        POSTGRES_DB = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      environmentFiles = [ secrets ];
      volumes = [ "/srv/immich/postgres:/var/lib/postgresql" ];
      podman.sdnotify = "healthy";
      extraOptions = [
        "--network=immich"
        "--shm-size=128m"
        "--health-cmd=pg_isready -U immich -d immich"
        "--health-interval=10s"
      ];
    };

    immich-redis = {
      image = "docker.io/valkey/valkey:9";
      podman.sdnotify = "healthy";
      extraOptions = [
        "--network=immich"
        "--health-cmd=valkey-cli ping"
        "--health-interval=10s"
      ];
    };

    immich-server = {
      image = "ghcr.io/immich-app/immich-server:v3";
      dependsOn = [
        "immich-postgres"
        "immich-redis"
      ];
      environment = {
        DB_USERNAME = "immich";
        DB_DATABASE_NAME = "immich";
        DB_HOSTNAME = "immich-postgres";
        REDIS_HOSTNAME = "immich-redis";
      };
      environmentFiles = [ secrets ];
      ports = [ "127.0.0.1:2283:2283" ];
      volumes = [
        "/storage/gallery:/data"
        "/etc/localtime:/etc/localtime:ro"
      ];
      extraOptions = [
        "--network=immich"
        "--device=/dev/dri/renderD128"
      ];
    };

    immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:v3";
      volumes = [ "/srv/immich/model-cache:/cache" ];
      extraOptions = [ "--network=immich" ];
    };
  };

  systemd.services = {
    immich-init = {
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        StateDirectory = "immich-containers";
        StateDirectoryMode = "0700";
        UMask = "0077";
      };
      script = ''
        ${pkgs.podman}/bin/podman network create --ignore immich
        if [ ! -e ${secrets} ]; then
          password=$(${pkgs.openssl}/bin/openssl rand -hex 32)
          printf 'POSTGRES_PASSWORD=%s\nDB_PASSWORD=%s\n' "$password" "$password" > ${secrets}.tmp
          mv ${secrets}.tmp ${secrets}
        fi
      '';
    };

    podman-immich-postgres = {
      requires = [ "immich-init.service" ];
      after = [ "immich-init.service" ];
    };
    podman-immich-redis = {
      requires = [ "immich-init.service" ];
      after = [ "immich-init.service" ];
    };
    podman-immich-machine-learning = {
      requires = [ "immich-init.service" ];
      after = [ "immich-init.service" ];
    };
  };
}
