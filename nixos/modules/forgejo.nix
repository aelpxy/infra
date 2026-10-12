{ pkgs, ... }:

let
  domain = "git.example.com";
in
{
  networking.firewall.allowedTCPPorts = [ 2222 ];

  virtualisation.oci-containers = {
    backend = "podman";
    containers = {
      forgejo-db = {
        image = "docker.io/library/postgres:18";
        environment = {
          POSTGRES_DB = "forgejo";
          POSTGRES_USER = "forgejo";
        };
        environmentFiles = [ "/var/lib/forgejo-containers/database.env" ];
        volumes = [ "forgejo-postgres:/var/lib/postgresql" ];
        podman.sdnotify = "healthy";
        extraOptions = [
          "--network=forgejo"
          "--health-cmd=pg_isready -h 127.0.0.1 -U forgejo -d forgejo"
          "--health-interval=5s"
          "--health-timeout=5s"
          "--health-retries=10"
          "--health-start-period=30s"
        ];
      };

      forgejo = {
        image = "codeberg.org/forgejo/forgejo:15";
        dependsOn = [ "forgejo-db" ];
        environment = {
          USER_UID = "1000";
          USER_GID = "1000";
          FORGEJO__database__DB_TYPE = "postgres";
          FORGEJO__database__HOST = "forgejo-db:5432";
          FORGEJO__database__NAME = "forgejo";
          FORGEJO__database__USER = "forgejo";
          FORGEJO__database__SSL_MODE = "disable";
          FORGEJO__server__DOMAIN = domain;
          FORGEJO__server__ROOT_URL = "https://${domain}/";
          FORGEJO__server__HTTP_ADDR = "0.0.0.0";
          FORGEJO__server__HTTP_PORT = "3000";
          FORGEJO__server__DISABLE_SSH = "false";
          FORGEJO__server__START_SSH_SERVER = "false";
          FORGEJO__server__SSH_DOMAIN = "ssh.example.com";
          FORGEJO__server__SSH_PORT = "2222";
          FORGEJO__security__INSTALL_LOCK = "true";
          FORGEJO__service__DISABLE_REGISTRATION = "true";
          FORGEJO__session__COOKIE_SECURE = "true";
        };
        environmentFiles = [ "/var/lib/forgejo-containers/database.env" ];
        volumes = [ "forgejo-data:/data" ];
        ports = [
          "127.0.0.1:3000:3000"
          "2222:22"
        ];
        extraOptions = [ "--network=forgejo" ];
      };
    };
  };

  services.cloudflared.tunnels."REPLACE_WITH_TUNNEL_ID".ingress.${domain} = "http://127.0.0.1:3000";

  systemd.services.forgejo-init = {
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      StateDirectory = "forgejo-containers";
      StateDirectoryMode = "0700";
      UMask = "0077";
    };
    script = ''
      ${pkgs.podman}/bin/podman network create --ignore forgejo
      if [ ! -e /var/lib/forgejo-containers/database.env ]; then
        database_password=$(${pkgs.openssl}/bin/openssl rand -hex 32)
        printf 'POSTGRES_PASSWORD=%s\nFORGEJO__database__PASSWD=%s\n' "$database_password" "$database_password" > /var/lib/forgejo-containers/database.env.tmp
        mv /var/lib/forgejo-containers/database.env.tmp /var/lib/forgejo-containers/database.env
      fi
    '';
  };

  systemd.services.podman-forgejo-db = {
    requires = [ "forgejo-init.service" ];
    after = [ "forgejo-init.service" ];
  };
}
