{ config, lib, ... }:
with lib;
let
  rootCfg = config.vps.remnawave;
in
{
  config = mkIf (rootCfg.panel.backup.enable && rootCfg.type == "panel") {
    sops.secrets = {
      "panel/postgres-password" = { };
      "panel/telegram-bot-token" = { };
      "panel/telegram-chat-id" = { };
      "panel/backup-ssh-target" = { };
      "panel/backup-ssh-key" = { };
    };

    sops.templates."remnawave-backup.env".content = ''
      POSTGRES_PASSWORD=${config.sops.placeholder."panel/postgres-password"}
      TELEGRAM_BOT_TOKEN=${config.sops.placeholder."panel/telegram-bot-token"}
      TELEGRAM_CHAT_ID=${config.sops.placeholder."panel/telegram-chat-id"}
      BACKUP_SSH_TARGET=${config.sops.placeholder."panel/backup-ssh-target"}
    '';
  };
}
