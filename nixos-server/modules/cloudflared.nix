{ ... }:

{
  # tunnel.env holds TUNNEL_TOKEN=<token from the cloudflare dashboard>
  virtualisation.oci-containers.containers.cloudflared = {
    image = "docker.io/cloudflare/cloudflared:latest";
    cmd = [
      "tunnel"
      "--no-autoupdate"
      "run"
    ];
    environmentFiles = [ "/var/lib/cloudflared/tunnel.env" ];
    extraOptions = [
      "--network=jellyfin"
      "--network=immich"
    ];
  };

  systemd.services.podman-cloudflared = {
    requires = [
      "jellyfin-network.service"
      "immich-init.service"
    ];
    after = [
      "jellyfin-network.service"
      "immich-init.service"
    ];
  };
}
