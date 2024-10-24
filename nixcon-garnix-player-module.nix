{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.playerConfig;
in
{
  options.playerConfig = {

    githubLogin = lib.mkOption {
      type = lib.types.str;
      description = "The github user/organization to use for the player";
    };

    githubRepo = lib.mkOption {
      type = lib.types.str;
      description = "The github repository to use for the player";
    };

    sshKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "The ssh public key to add to the `me` authorized keys";
    };

    webserver = lib.mkOption {
      type = lib.types.package;
      description = "The webserver package to run";
    };

    gameServerUrl = lib.mkOption {
      type = lib.types.str;
      description = "The url of the game server";
      default = "https://game-server.main.nixcon-2024-game-server.garnix-io.garnix.me";
    };
  };

  config = {
    systemd.services.webserver = {
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "The player webserver service";
      script = lib.getExe cfg.webserver;
      environment = {
        PORT = "8080";
      };
      serviceConfig = {
        DynamicUser = true;
        ExecStartPre = "${lib.getExe pkgs.curl} -v --retry 3 --retry-delay 0 --retry-all-errors --fail -X POST ${cfg.gameServerUrl}/register/${cfg.githubLogin}/${cfg.githubRepo}";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = {
        "default" = {
          default = true;
          locations."/".proxyPass = "http://127.0.0.1:8080";
        };
      };
    };

    users.users.me = {
      isNormalUser = true;
      description = "me";
      extraGroups = [
        "wheel"
        "systemd-journal"
      ];
      openssh.authorizedKeys.keys =
        if cfg.sshKey == null
        then []
        else [ cfg.sshKey ];
    };

    garnix.server.enable = true;
    # garnix.server.persistence.enable = true;
    # garnix.server.persistence.name = "true";

    services.openssh.enable = true;

    security.sudo = {
      enable = true;
      execWheelOnly = true;
      wheelNeedsPassword = false;
    };

    networking = {
      hostName = "player";
      firewall.allowedTCPPorts = [ 80 ];
    };

    virtualisation.vmVariant.services.getty.autologinUser = "me";
    system.stateVersion = "24.11";
  };
}
