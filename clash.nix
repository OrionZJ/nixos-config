{ pkgs, config, lib, ... }:
with lib;
let
  cfg = config.euphgh.sys.clash;
  defaultUser = "clash";
in
{
  options.euphgh.sys.clash = {
    enable = mkEnableOption "clash service";
    package = mkOption {
      type = types.package;
      default = pkgs.clash-meta;
    };
    workingDirectory = mkOption {
      type = types.str;
      default = "/tmp";
    };
    configDirectory = mkOption {
      type = types.str;
      default = "/tmp";
    };
    configPath = mkOption {
      type = types.path;
    };
    user = mkOption {
      default = defaultUser;
      type = types.str;
    };
    group = mkOption {
      default = defaultUser;
      type = types.str;
    };
  };
  config =
    mkIf cfg.enable {

      users.users = optionalAttrs (cfg.user == defaultUser) {
        ${defaultUser} = {
          description = "clash user";
          group = defaultUser;
          isSystemUser = true;
        };
      };

      users.groups = optionalAttrs (cfg.user == defaultUser) {
        ${defaultUser} = {
          members = [ defaultUser ];
        };
      };

      systemd.services.clash = {

        wantedBy = [ "multi-user.target" ];
        after = [ "systemd-networkd.service" ];
        description = "Clash Daemon";

        serviceConfig = rec {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          PrivateTmp = true;
          WorkingDirectory = "${cfg.workingDirectory}";
          ExecStartPre = "${pkgs.coreutils}/bin/ln -s ${pkgs.dbip-country-lite}/share/dbip/dbip-country-lite.mmdb ${cfg.configDirectory}/Country.mmdb";
          ExecStart = "${lib.getExe cfg.package}"
            + " -d ${cfg.configDirectory}"
            + " -f ${cfg.configPath}";
          Restart = "on-failure";
          CapabilityBoundingSet = [ "CAP_NET_ADMIN" "CAP_NET_RAW" "CAP_NET_BIND_SERVICE" ];
          AmbientCapabilities = CapabilityBoundingSet;
        };
      };
    };
}
