{ pkgs, ... }:
{
  services = {
    postgresql = {
      enable = true;
      ensureDatabases = [ "hedgedoc" ];
    };
    hedgedoc = {
      enable = true;
      configureNginx = true;
      settings = {
        domain = "notes.example.com";
        db = {
          dialect = "postgresql";
          host = "/run/postgresql";
        };
      };
      environmentFile = config.sops.templates."hedgedoc/environment".path;
    };
    nginx =
      let
        modsecurity_crs = pkgs.fetchFromGitHub {
          owner = "coreruleset";
          repo = "coreruleset";
          rev = "v4.29.0";
          hash = "sha256-NvBwGFgch+7tnGjcpm47n0mGy0vj5i+JWtb7d033u2s=";
        };
        modsecurity_conf = pkgs.writeText "modsecurity.conf" ''
          SecAuditEngine RelevantOnly
          SecAuditLog /var/log/nginx/modsec.json
          SecAuditLogFormat JSON
          SecAuditLogParts ABIJDEFHZ

          SecRuleEngine On

          SecDefaultAction "phase:1,log,auditlog,pass"
          SecDefaultAction "phase:2,log,auditlog,pass"

          SecRuleRemoveByTag "platform-iis"
          SecRuleRemoveByTag "platform-windows"

          # socket.io endpoint: Request content type is not allowed by policy
          SecRule REQUEST_HEADERS:Host "@streq hedgedoc.example.de" \
            "chain, id:10000, phase:1, pass, nolog"
            SecRule REQUEST_URI "@beginsWith /socket.io/" \
              "ctl:ruleRemoveById=920420"

          # Delete note: Method is not allowed by policy
          SecRule REQUEST_HEADERS:Host "@streq hedgedoc.example.de" \
            "chain, id:10001, phase:1, pass, nolog"
            SecRule REQUEST_URI "@beginsWith /history/" \
              "ctl:ruleRemoveById=911100"

          SecAction "id:900000,phase:1,pass,t:none,nolog,setvar:tx.blocking_paranoia_level=2"
          SecAction "id:900010,phase:1,pass,t:none,nolog,setvar:tx.enforce_bodyproc_urlencoded=1"
          SecAction "id:900990,phase:1,pass,t:none,nolog,setvar:tx.crs_setup_version=400"

          Include ${modsecurity_crs}/rules/*.conf
        '';
      in
      {
        additionalModules = [ pkgs.nginxModules.modsecurity ];
        appendHttpConfig = ''
          modsecurity on;
          modsecurity_rules_file ${modsecurity_conf};
        '';
      };
  };
  security.acme.acceptTerms = true;
}
