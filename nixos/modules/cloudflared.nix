{ ... }:

{
  services.cloudflared = {
    enable = true;
    tunnels."REPLACE_WITH_TUNNEL_ID" = {
      credentialsFile = "/var/lib/cloudflared/REPLACE_WITH_TUNNEL_ID.json";
      default = "http_status:404";
      ingress = {
        "app.example.com" = "http://localhost:8080";
      };
    };
  };
}
