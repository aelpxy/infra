{ ... }:

{
  networking.firewall.extraCommands = ''
    iptables -A nixos-fw -p tcp -s 192.168.0.120 -m multiport --dports 9100,9882 -j nixos-fw-accept
  '';

  environment.etc."containers/systemd/users/1000/node-exporter.container".text = ''
    [Unit]
    Description=Prometheus node exporter

    [Container]
    Image=quay.io/prometheus/node-exporter:v1
    ContainerName=node-exporter
    Network=host
    PodmanArgs=--pid=host
    Volume=/:/host:ro,rslave
    Exec=--path.rootfs=/host --web.listen-address=192.168.0.100:9100
    AutoUpdate=registry

    [Service]
    Restart=always
    TimeoutStartSec=300

    [Install]
    WantedBy=default.target
  '';

  environment.etc."containers/systemd/users/1000/podman-exporter.container".text = ''
    [Unit]
    Description=Prometheus podman exporter
    Wants=podman.socket
    After=podman.socket

    [Container]
    Image=quay.io/navidys/prometheus-podman-exporter:v2.0.0
    ContainerName=podman-exporter
    PublishPort=192.168.0.100:9882:9882
    User=0
    Volume=%t/podman/podman.sock:/run/podman/podman.sock
    Environment=CONTAINER_HOST=unix:///run/podman/podman.sock
    Exec=--collector.enable-all
    AutoUpdate=registry

    [Service]
    Restart=always
    TimeoutStartSec=300

    [Install]
    WantedBy=default.target
  '';
}
