{ pkgs, ... }:

let
  secrets = "/var/lib/clickhouse-container/secrets.env";
in
{
  networking.firewall.allowedTCPPorts = [
    8123
    9000
  ];

  systemd.tmpfiles.rules = [
    "d /srv/clickhouse/data 0750 root root -"
    "d /srv/clickhouse/logs 0750 root root -"
  ];

  virtualisation.oci-containers.containers.clickhouse = {
    image = "docker.io/clickhouse/clickhouse-server:latest";
    environment = {
      CLICKHOUSE_USER = "default";
      CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT = "1";
    };
    environmentFiles = [ secrets ];
    ports = [
      "8123:8123"
      "9000:9000"
    ];
    volumes = [
      "/srv/clickhouse/data:/var/lib/clickhouse"
      "/srv/clickhouse/logs:/var/log/clickhouse-server"
    ];
    extraOptions = [ "--ulimit=nofile=262144:262144" ];
  };

  systemd.services.clickhouse-init = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "clickhouse-container";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      if [ ! -e ${secrets} ]; then
        printf 'CLICKHOUSE_PASSWORD=%s\n' "$(${pkgs.openssl}/bin/openssl rand -hex 24)" > ${secrets}.tmp
        mv ${secrets}.tmp ${secrets}
      fi
    '';
  };

  systemd.services.podman-clickhouse = {
    requires = [ "clickhouse-init.service" ];
    after = [ "clickhouse-init.service" ];
  };
}
