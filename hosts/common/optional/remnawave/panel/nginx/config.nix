{
  config,
  lib,
  ...
}:
with lib;
let
  rootCfg = config.vps.remnawave;
  domain = config.sops.placeholder."domain";
  panelName = "${rootCfg.subdomain}.${domain}";
  subName = "${rootCfg.panel.sub-page.subdomain}.${domain}";
  authName = "${rootCfg.panel.auth.subdomain}.${domain}";
in
{
  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    sops.secrets = {
      "domain" = { };
      "letsencrypt/email" = { };
      "porkbun/api-key" = { };
      "porkbun/secret-key" = { };
    };

    sops.templates."letsencrypt.env".content = ''
      DOMAIN=${domain}
      LEGO_EMAIL=${config.sops.placeholder."letsencrypt/email"}
      PORKBUN_API_KEY=${config.sops.placeholder."porkbun/api-key"}
      PORKBUN_SECRET_API_KEY=${config.sops.placeholder."porkbun/secret-key"}
    '';

    sops.templates."nginx.conf" = {
      owner = config.services.nginx.user;
      content = ''
        map $http_upgrade $connection_upgrade {
            default upgrade;
            "" close;
        }

        ssl_ecdh_curve X25519:prime256v1:secp384r1;
        ssl_prefer_server_ciphers on;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;

        server {
            listen 80;
            listen [::]:80;
            server_name ${panelName} ${subName} ${authName};
            return 301 https://$host$request_uri;
        }

        server {
            listen 443 ssl;
            listen [::]:443 ssl;
            http2 on;
            server_name ${panelName};
            ssl_certificate /var/lib/certs/live/fullchain.pem;
            ssl_certificate_key /var/lib/certs/live/privkey.pem;

            location = /tinyauth {
                internal;
                proxy_pass http://127.0.0.1:3002/api/auth/nginx;
                proxy_pass_request_body off;
                proxy_set_header Content-Length "";
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $host;
                proxy_set_header X-Forwarded-Uri $request_uri;
                proxy_set_header X-Api-Key $http_x_api_key;
                proxy_set_header Authorization $http_authorization;
            }

            location / {
                auth_request /tinyauth;
                auth_request_set $tinyauth_location $upstream_http_x_tinyauth_location;
                error_page 401 403 =302 $tinyauth_location;

                proxy_http_version 1.1;
                proxy_pass http://127.0.0.1:3000;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header X-Forwarded-Host $host;
                proxy_set_header X-Forwarded-Port $server_port;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
                proxy_set_header Authorization $http_authorization;
                proxy_set_header X-Api-Key "";
                proxy_read_timeout 60s;
                proxy_send_timeout 60s;
            }
        }

        server {
            listen 443 ssl;
            listen [::]:443 ssl;
            http2 on;
            server_name ${subName};
            ssl_certificate /var/lib/certs/live/fullchain.pem;
            ssl_certificate_key /var/lib/certs/live/privkey.pem;

            location / {
                proxy_http_version 1.1;
                proxy_pass http://127.0.0.1:3010;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
            }
        }

        server {
            listen 443 ssl;
            listen [::]:443 ssl;
            http2 on;
            server_name ${authName};
            ssl_certificate /var/lib/certs/live/fullchain.pem;
            ssl_certificate_key /var/lib/certs/live/privkey.pem;

            location / {
                proxy_http_version 1.1;
                proxy_pass http://127.0.0.1:3002;
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto $scheme;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection $connection_upgrade;
            }
        }

        server {
            listen 80 default_server;
            listen [::]:80 default_server;
            listen 443 ssl default_server;
            listen [::]:443 ssl default_server;
            http2 on;
            server_name _;
            ssl_certificate /var/lib/certs/live/fullchain.pem;
            ssl_certificate_key /var/lib/certs/live/privkey.pem;
            ssl_reject_handshake on;
            return 444;
        }
      '';
    };
  };
}
