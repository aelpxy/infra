{ ... }:

{
  environment.etc."containers/systemd/users/1000/cloudflared.container".text = ''
    [Unit]
    Description=Cloudflare tunnel
    ConditionPathExists=%h/.config/cloudflared/tunnel.env

    [Container]
    Image=docker.io/cloudflare/cloudflared:latest
    ContainerName=cloudflared
    EnvironmentFile=%h/.config/cloudflared/tunnel.env
    Exec=tunnel --no-autoupdate run
    AutoUpdate=registry

    [Service]
    Restart=always
    TimeoutStartSec=300

    [Install]
    WantedBy=default.target
  '';
}
