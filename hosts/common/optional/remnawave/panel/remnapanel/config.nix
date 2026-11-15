{
  config,
  lib,
  ...
}:
with lib;
let
  rootCfg = config.vps.remnawave;
  moduleCfg = rootCfg.panel;
  domain = config.sops.placeholder."domain";
in
{
  config = mkIf (rootCfg.enable && rootCfg.type == "panel") {
    sops.secrets = {
      "domain" = { };
      "panel/app-secret" = { };
      "panel/postgres-password" = { };
      "panel/metrics/user" = { };
      "panel/metrics/password" = { };
    };

    sops.templates."remnapanel.env".content = ''
      APP_PORT=${toString moduleCfg.appPort}
      METRICS_USER=${config.sops.placeholder."panel/metrics/user"}
      METRICS_PASS=${config.sops.placeholder."panel/metrics/password"}
      METRICS_PORT=${toString moduleCfg.metricsPort}
      API_INSTANCES=1
      DATABASE_URL=postgresql://postgres:${
        config.sops.placeholder."panel/postgres-password"
      }@remnawave-db:5432/postgres
      REDIS_HOST=remnawave-valkey
      REDIS_PORT=${toString moduleCfg.redis.port}
      APP_SECRET=${config.sops.placeholder."panel/app-secret"}
      IS_TELEGRAM_NOTIFICATIONS_ENABLED=false
      WEBHOOK_ENABLED=false
      PANEL_DOMAIN=${moduleCfg.subdomain}.${domain}
      FRONT_END_DOMAIN=${moduleCfg.subdomain}.${domain}
      SUB_PUBLIC_DOMAIN=sub.${domain}
    '';
  };
}
