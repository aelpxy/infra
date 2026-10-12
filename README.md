# infra

NixOS configuration for my server.

## Layout

```
nixos/
  configuration.nix      system, users, ssh, podman
  modules/
    cloudflared.nix      cloudflare tunnel
```

## Setup

1. Install NixOS on the server. The installer generates `/etc/nixos/hardware-configuration.nix`, keep it.
2. Copy `system.stateVersion` and, on BIOS machines, the boot loader lines from the generated `configuration.nix` into this repo's one.
3. Add your SSH public key to `openssh.authorizedKeys.keys`.
4. Copy the contents of `nixos/` into `/etc/nixos/`.
5. Run `sudo nixos-rebuild switch`.

## Cloudflare tunnel

Leave `./modules/cloudflared.nix` out of `imports` until the tunnel exists.

```
nix shell nixpkgs#cloudflared
cloudflared tunnel login
cloudflared tunnel create server
cloudflared tunnel route dns server app.example.com
sudo mkdir -p /var/lib/cloudflared
sudo mv ~/.cloudflared/<tunnel-id>.json /var/lib/cloudflared/
sudo chmod 600 /var/lib/cloudflared/<tunnel-id>.json
```

Put the tunnel ID and hostnames in `nixos/modules/cloudflared.nix`, add it back to `imports`, and rebuild. The credentials JSON is a secret and stays on the server.

## Containers

Run containers rootless as your user and bind ports to localhost so they're only reachable through the tunnel:

```
podman run -d -p 127.0.0.1:8080:80 myapp
```

## License

[MIT](LICENSE)
