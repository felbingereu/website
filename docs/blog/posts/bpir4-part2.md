---
date:
  created: 2025-10-24
authors:
- nicof2000
categories:
- NixOS
- Networking
draft: true
---

# NixOS Router: Banana PI R4 (Part 2)

Während sich der [erste Teil](./bpir4-part1.md) dieses Blogartikels mit der grundsätzlichen
Integration von NixOS auf dem BPI-R4 beschäftigt, beschreibt dieser Teil das aufsetzen
verschiedener Netzwerkdienste unter NixOS.

Grundsätzlich lassen sich die Kapitel auch auf andere NixOS Systeme übertragen.

<!-- more -->

## Netzwerkschnittstellen mit ifstate
### DSA (aus 1)
### Wireguard
Die Verwendung von Wireguard erfordert, wie im ersten Teil beschrieben, eine Anpassung des Linux Kernels.
Anschließend kann die Konfiguration wie gewohnt per ifstate durchgeführt werden:
```nix
{ config, ... }:
let
  interface = "wg0";
in
{
  sops.secrets = {
    "wireguard/private-key" = { };
    "wireguard/psk" = { };
  };

  networking = {
    ifstate.settings.interfaces."${interface}" = {
      addresses = [
        "2001:db8:beef::1/64"
      ];
      link = {
        state = "up";
        kind = "wireguard";
      };
      wireguard = {
        private_key = "!include ${config.sops.secrets."wireguard/private-key".path}";
        peers."4A2eXsg50xYxUG5qXyW2AVziYlWnFuOZIb3GEkzSR3E=" = {
          preshared_key = "!include ${config.sops.secrets."wireguard/psk".path}";
          allowedips = [ "2001:db8:beef::2/128" ];
          endpoint = "[2001:db8::1]:51820";
          persistent_keepalive_interval = 30;
        };
      };
    };
    nftables.tables = {
      nixos-fw.content = ''
        chain input-allow {
          iifname ${interface} tcp dport 179 accept
          iifname ${interface} udp dport 53 accept
          iifname ${interface} tcp dport 22 accept
          iifname ${interface} tcp dport { 9100, 9342, 9586 } accept
        };
        chain output-allow {
          oifname ${interface} tcp dport 179 accept
          oifname ${interface} udp dport 53 accept
          oifname ${interface} tcp dport 22 accept

          oifname wan ip daddr 185.170.115.193 udp dport 51834 accept
        };
      '';
    };
  };
}
```

## Firewall: nftables
tbd, nichts besonderes

## DNS Server: knot resolver
```nix
{ pkgs, ... }:
{
  services.kresd = {
    enable = true;
    listenPlain = [
      "127.0.0.1:53"
      "192.0.2.1:53"
      "[::1]:53"
    ];
    listenTLS = [ # now until we've got a good dns name
      "192.0.2.1:853"
    ];
    extraConfig =
      ''
        net.tls("/var/lib/acme/router.example.com/fullchain.pem", "/var/lib/acme/router.example.com/key.pem")

        -- forward everything else to the public dns servers over dns over tls
        policy.add(policy.all(policy.TLS_FORWARD({
          {'1.1.1.1', hostname='one.one.one.one'},
          {'1.0.0.1', hostname='one.one.one.one'},
          {'2606:4700:4700::1111', hostname='one.one.one.one'},
          {'2606:4700:4700::1001', hostname='one.one.one.one'},

          {'8.8.8.8', hostname='dns.google'},
          {'8.8.4.4', hostname='dns.google'},
          {'2001:4860:4860::8888', hostname='dns.google'},
          {'2001:4860:4860::8844', hostname='dns.google'},
        })))
      '';
  };

  users.users.knot-resolver.extraGroups = [ "acme" ];
  security.acme.certs."router.example.com" = { };

  # allow outgoing traffic to defined servers for DoT
  networking.nftables.tables.nixos-fw.content = ''
    chain input-allow {
      # dns
      iifname "br-lan" udp dport 53 accept
      # dns over tls
      iifname "br-lan" tcp dport 853 accept
    }
    chain output-allow {
      tcp dport 853 ip daddr {
        # cloudflare
        "1.1.1.1",
        "1.0.0.1",
        # google
        "8.8.8.8",
        "8.8.4.4",
      } accept

      tcp dport 853 ip6 daddr {
        # cloudflare
        "2606:4700:4700::1111",
        "2606:4700:4700::1001",
        # google
        "2001:4860:4860::8888",
        "2001:4860:4860::8844",
      } accept
    }
  '';
}
```

## Adressvergabe: kea + radvd
### DHCPv4
```nix
{
  services.kea.dhcp4 = {
    enable = true;
    settings = {
      interfaces-config.interfaces = [ "br-lan" ];
      subnet4 = [
        {
          id = 1;
          subnet = "192.0.2.0/24";
          pools = [
            {
              pool = "192.0.2.100-192.0.2.199";
            }
          ];
          option-data = [
            {
              name = "domain-name-servers";
              data = "192.0.2.1";
            }
            {
              name = "routers";
              data = "192.0.2.1";
            }
            {
              name = "ntp-servers";
              data = "192.0.2.1";
            }
          ];
        }
      ];
    };
  };
}
```

### SLAAC
tbd
### DHCPv6 (für PD)
tbd

## Monitoring: LLDP + Prometheus + SNMP
### LLDP
```nix
{
  services.lldpd.enable = true;
}
```

### Prometheus Exporters
```nix
let
  listenAddress = "192.0.2.1";
in {
  services.prometheus.exporters = {
    node = {
      enable = true;
      inherit listenAddress;
      enabledCollectors = [ "systemd" ];
    };
    wireguard = {
      enable = true;
      inherit listenAddress;
      withRemoteIp = true;
    };
    frr = {
      enable = true;
      inherit listenAddress;
      disabledCollectors = [
        "bfd"
        "ospf"
      ];
      enabledCollectors = [
        "bgp"
        "bgp6"
      ];
      # fix permissions to access tockets
      user = "frr";
      group = "frrvty";
    };
  };

  # fixup permission to access frr sockets
  systemd.services.prometheus-frr-exporter.serviceConfig.RestrictAddressFamilies = [ "AF_UNIX" ];

  networking.nftables.tables.nixos-fw.content = ''
    chain input-allow {
      iifname "br-lan" tcp dport { 9100, 9586, 9342 } accept
    }
  '';
}
```

### SNMP
```sh
snmpwalk -v3 -u ro -l authPriv -a SHA -A Str0ng@uth3ntic@ti0n -x AES -X Str0ngPriv@cy 192.0.2.1
```
```nix
{ config, pkgs, ... }:
{
  sops = {
    secrets = {
      "snmp/user" = { };
      "snmp/auth" = { };
      "snmp/privacy" = { };
    };
    templates."snmp/config".content = let
      user = config.sops.placeholder."snmp/user";
      auth = config.sops.placeholder."snmp/auth";
      privacy = config.sops.placeholder."snmp/privacy";
    in ''
      createUser ${user} SHA "${auth}" AES "${privacy}"
      rouser ${user} authPriv
    '';
  };

  environment.systemPackages = with pkgs; [ net-snmp ];

  services.snmpd = {
    enable = true;
    listenAddress = "192.0.2.1";
    configFile = config.sops.templates."snmp/config".path;
  };

  networking.nftables.tables.nixos-fw.content = ''
    chain input-allow {
      iifname "br-lan" udp dport 161 accept
    };
  '';
}
```

## Dynamisches Routing: FRR
TODO vrf
```nix
{ config, ... }:
{
  services.frr = {
    bgpd.enable = true;
    config = ''
      router bgp 65000
        no bgp default ipv4-unicast
        bgp log-neighbor-changes
        bgp router-id 192.0.2.1
        !
        neighbor fabric peer-group
        neighbor fabric remote-as internal
        neighbor fabric capability extended-nexthop
        neighbor wan interface peer-group fabric
        !
        address-family ipv4 unicast
          network 192.0.2.0/24
          !
          neighbor fabric activate
          neighbor fabric soft-reconfiguration inbound
        exit-address-family
        !
        address-family ipv6 unicast
          network 2001:db8:dead::/48
          !
          neighbor fabric activate
          neighbor fabric soft-reconfiguration inbound
        exit-address-family
      exit
      !
      end
    '';
  };

  networking.nftables.tables = {
    nixos-fw.content = ''
      chain input-allow {
        iifname wan ip6 daddr fe80::/10 tcp dport 179 accept
      };
      chain output-allow {
        oifname wan ip6 daddr fe80::/10 tcp dport 179 accept
      };
    '';
  };
}
```

## WiFi: hostapd
tbd

## L7 Firewall
TODO

## IDS: Suricata
```nix
{ lib, ... }:
{
  services.suricata = {
    enable = true;
    disabledRules = map (x: toString x) (
      (lib.range 2250000 2250009)     # Modbus
      ++ (lib.range 2270000 2270004)  # DNP3
    );
    settings = {
      vars.address-groups.HOME_NET = "192.0.2.0/24";
      af-packet = [
        {
          interface = "wan";
        }
      ];
      outputs = [
        {
          fast = {
            enabled = true;
            filename = "fast.log";
            append = "yes";
          };
        }
        {
          eve-log = {
            enabled = true;
            filetype = "regular";
            filename = "eve.json";
            community-id = true;
            types = [
              {
                alert.tagged-packets = "yes";
              }
            ];
          };
        }
      ];
    };
  };
}
```

## NAT64 Gateway
```nix
{ sbcPkgs, ... }:
{
  boot = {
    kernelModules = [ "jool" ];
    extraModulePackages = with sbcPkgs.linuxPackages_frankw_latest_bananaPiR4; [ jool ];
  };

  networking.jool = {
    enable = true;
    nat64."br-lan.10".framework = "netfilter";
  };

  # Advertise NAT64 prefix, so CLAT (Customer-side Translator) can translate in the kernel
  # TODO think about switching to corerad, because it has easier config tree
  # - https://github.com/mdlayher/corerad/blob/main/internal/config/reference.toml
  # https://francis.begyn.be/blog/ipv6-nixos-router
  services.radvd = {
    enable = true;
    config = ''
      interface br-lan.10 {
        AdvSendAdvert on;
        prefix ::/64 { };
        nat64prefix 64:ff9b::/96 { };
     };
    '';
  };
}
```

## Radius für 802.1X
```nix
{
  services.freeradius.enable = true;

  # TODO create from ${pkgs.freeradius}/etc/raddb
  environment.etc = { };
}
```

## asterisk: Telefonanlage
```nix
{
  services.asterisk = {
    enable = true;
    # TODO
    confFiles = {
      "modules.conf" = ''
        [modules]
        autoload = yes

        ; deprecated modules
        noload = res_adsi
        noload = app_getcpeid
        noload = app_adsiprog
      '';

      "pjsip.conf" = ''
        ; we use UDP for transport
        [transport-udp]
        type=transport
        protocol=udp
        bind=0.0.0.0

        ; Note: this defines a macro, to shorten the config further down
        [endpoint_internal](!)
        type=endpoint
        context=from-internal
        disallow=all
        allow=ulaw

        [auth_userpass](!)
        type=auth
        auth_type=userpass

        [aor_dynamic](!)
        type=aor
        max_contacts=1


        ; here come the definitions for our phones, using the macros from above

        ; lecture hall 1
        [saal1](endpoint_internal)
        auth=saal1
        aors=saal1
        [saal1](auth_userpass)
        ; well, maybe set a better password than this
        password=saal1
        username=saal1
        [saal1](aor_dynamic)

        ; lecture hall 2
        [saal2](endpoint_internal)
        auth=saal2
        aors=saal2
        [saal2](auth_userpass)
        password=saal2
        username=saal2
        [saal2](aor_dynamic)

        [backoffice](endpoint_internal)
        auth=backoffice
        aors=backoffice
        [backoffice](auth_userpass)
        password=backoffice
        username=backoffice
        [backoffice](aor_dynamic)

      '';
      "extensions.conf" = ''
        [from-internal]
        ; dial the lecture rooms & backoffice
        ; the syntax is NUMBER,SEQUENCE,FUNCTION
        ; to call someone do Dial(MODULE/account, timeout)
        exten => 1001,1,Dial(PJSIP/saal1,20)
        exten => 1002,1,Dial(PJSIP/saal2,20)
        exten => 1600,1,Dial(PJSIP/backoffice,20)

        ; Dial 100 for "hello, world"
        ; this is useful when configuring/debugging clients (snoms)
        exten => 100,1,Answer()
        same  =>     n,Wait(1)
        same  =>     n,Playback(hello-world)
        same  =>     n,Hangup()
        ; note: "n" is a keyword meaning "the last line's value, plus 1"
        ; "same" is a keyword referring to the last-defined extension
      '';

      "http.conf" = ''
        [general]
        enabled = yes
        enablestatic = yes
        enable_status = no
        bindaddr = [::1]
        bindport = 8088
      '';
      "prometheus.conf" = ''
        [general]
        enabled = yes
        core_metrics_enabled = yes
        uri = metrics
        ; auth_username =
        ; auth_password =
      '';
    };
  };

  networking.nftables.tables.nixos-fw.content = ''
    chain input-allow {
      udp dport 5060 accept
      tcp dport 5061 accept
      tcp dport 8080 accept
      udp dport 10000-20000 accept
    }
    chain output-allow {
      accept
    }
  '';
}
```

<!-- Nice to have: Zigbee2MQTT Gateway -->

<!--

VI:
- Full Disk Encryption mit LUKS
- Entfernen von nicht benötigten Debugging Tools
-->

---

Fortsetzung folgt...
