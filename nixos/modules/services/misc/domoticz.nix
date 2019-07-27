{ config, lib, pkgs, ... }:

with lib;

let

  name = "domoticz";

  uid = config.ids.uids.domoticz;
  gid = config.ids.gids.domoticz;
  cfg = config.services.domoticz;

  domoticzConf = pkgs.writeText "domoticz.conf" ''
    http_port=${toString cfg.httpPort}
    ssl_port=${toString cfg.httpsPort}

    app_path=${pkgs.domoticz}/share/domoticz
    http_root=${pkgs.domoticz}/share/domoticz/www
    userdata_path=${cfg.dataDir}

    updates=no
    notimestamps=yes
    daemon=no

    ${cfg.extraConfig}
  '';

in {

  options = {

    services.domoticz = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to run Domoticz, the home automation system.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Extra directives added to to the end of Domoticz's configuration file.";
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/${name}";
        description = "The directory where Domoticz stores its state.";
      };

      user = mkOption {
        type = types.str;
        default = name;
        description = "User account under which Domoticz runs.";
      };

      group = mkOption {
        type = types.str;
        default = name;
        description = "Group account under which Domoticz runs.";
      };

      extraGroups = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "audio" ];
        description = "Extra groups to add the Domoticz user to, for hardware access.";
      };

      httpPort = mkOption {
        type = types.int;
        default = 8080;
        description = "HTTP port to use, 0 to disable";
      };

      httpsPort = mkOption {
        type = types.int;
        default = 0;
        description = "HTTPS port to use, 0 to disable";
      };

    };

  };

  config = mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' - ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.domoticz = {
      after = [ "network.target" ];
      description = "Home automation system";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = "${cfg.user}";
        Group = "${cfg.group}";
        ExecStart = "${pkgs.domoticz}/bin/domoticz -f ${domoticzConf}";
        Restart = "on-failure";
      };
    };

    users.users = optionalAttrs (cfg.user == name) (singleton {
      inherit uid;
      inherit name;
      group = cfg.group;
      extraGroups = cfg.extraGroups;
      description = "Domoticz user";
      home = "${cfg.dataDir}";
    });

    users.groups = optionalAttrs (cfg.group == name) (singleton {
      inherit name;
      gid = gid;
    });

  };

  meta = {
    maintainers = with maintainers; [ xvello ];
  };
}
