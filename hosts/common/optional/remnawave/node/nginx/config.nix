{ config, lib, ... }:
with lib;
let
  cfg = config.vps.remnawave;
  domain = config.sops.placeholder."domain";
  serverName = "${cfg.subdomain}.${domain}";
in
{
  config = mkIf (cfg.enable && cfg.type == "node") {
    sops.secrets = {
      "domain" = { };
      "letsencrypt/email" = { };
      "porkbun/api-key" = { };
      "porkbun/secret-key" = { };
    };

    sops.templates."letsencrypt.env" = {
      mode = "0400";
      content = ''
        DOMAIN=${config.sops.placeholder."domain"}
        LEGO_EMAIL=${config.sops.placeholder."letsencrypt/email"}
        PORKBUN_API_KEY=${config.sops.placeholder."porkbun/api-key"}
        PORKBUN_SECRET_API_KEY=${config.sops.placeholder."porkbun/secret-key"}
      '';
    };

    sops.templates."nginx.conf" = {
      mode = "0444";
      content = ''
        ssl_ecdh_curve X25519:prime256v1:secp384r1;
        ssl_prefer_server_ciphers on;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;

        server {
            listen 80;
            server_name ${serverName};
            root /var/lib/vps/decoy;
            log_not_found off;
            add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
            location / {
                try_files /index.html =404;
            }
        }

        server {
            server_name ${serverName};
            listen unix:/dev/shm/nginx.sock ssl proxy_protocol;
            http2 on;
            ssl_certificate /var/lib/certs/live/fullchain.pem;
            ssl_certificate_key /var/lib/certs/live/privkey.pem;
            ssl_trusted_certificate /var/lib/certs/live/fullchain.pem;

            location /xhttp/ {
                client_max_body_size 0;
                grpc_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                client_body_timeout 5m;
                grpc_read_timeout 315;
                grpc_send_timeout 5m;
                grpc_pass unix:/dev/shm/xrxh.socket;
            }

            root /var/lib/vps/decoy;
            log_not_found off;
            add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
            location / {
                try_files /index.html =404;
            }
        }

        server {
            listen unix:/dev/shm/nginx.sock ssl proxy_protocol default_server;
            server_name _;
            add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
            ssl_reject_handshake on;
            return 444;
        }
      '';
    };
  };
}
