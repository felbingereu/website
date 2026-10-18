---
date:
  created: 2026-12-01
authors:
- nicof2000
- herrluisi
categories:
- NixOS
draft: True
---

# Server- und Netzwerkinfrastruktur mit NixOS (2/3)
Im Rahmen des ersten Artikels wurden eine Einführung in die Konfiguration von Servern mit
NixOS gegeben. Dieser Teil beschäftigt sich mit Strukturierung einer Infrastruktur,
komplett basierende auf NixOS.

Im Fokus liegen dabei:

- Netzwerksegmentierung
- Implementierung des Prinzips: Ein Dienst pro System
- GitOps (CI/CD Pipeline) mit
  [Forgejo](https://forgejo.org/) und
  [Gradient](https://github.com/wavelens/gradient)

<!-- more -->

## Kurzvorstellung der geplanten Infrastruktur
Folgendes Netzwerkdiagramm beschreibt den Aufbau schematisch:
```mermaid
flowchart TB
  internet[Internet]@{ shape: cloud } --- router --- svc & inf & dmz
  svc[SVC]@{ shape: cloud } --- notes & auth
  inf[INF]@{ shape: cloud } --- git & build & mon & log
  dmz[DMZ]@{ shape: cloud } --- proxy & dns & time
```

Im Services (**SVC**) Netzsegment sind öffentlich erreichbare Dienste angesiedelt. Das im
vorherigen Teil des Blogartikel aufgesetzte System wird in die Systeme `notes` (hedgedoc)
und `auth` (keycloak) aufgeteilt.

Das Infrastruktur-Segment (**INF**) umfasst administrative Dienste. Während die Systeme
`git` und `build` für die Implementation von GitOps (forgejo, forgejo-actions und gradient)
genutzt werden, stellen `mon` und `log` die Monitoring (prometheus, grafana) bzw.
Log-Collection (graylog) dar.

In der demilitarisierten Zone (**DMZ**) werden Dienste bereitgestellt, die Systeme in den
isolierten Netzsegmenten (INF, SVC) ohne direkten Internetzugriff nutzen können, um
Informationen aus dem Internet abzurufen oder eigene Dienste erreichbar zu machen. Der
Server `proxy` stellt einen Forward-Proxy (squid) bereit, über den Systeme auf festgelegte
Internetseiten zugreifen können. Zusätzlich ermöglicht ein Reverse-Proxy (nginx) den Zugriff
aus dem Internet auf intern gehostete Dienste, die öffentlich erreichbar sein sollen
(hedgedoc, keycloak). Die Systeme `dns` und `time` stellen einen DNS Resolver (Knot Resolver)
sowie einen Zeitserver (chrony) zur Verfügung.

Der Router verbindet die Netzsegmente untereinander. Auf diese System werden strikte Firwallregeln für die Weiterleitung von IP Paketen definiert. Sowohl für den Zugriff auf das Infra Segment, als auch die Administration wird ein Wireguard Endpunkt auf dem Server bereitgestellt, mit dem sich Clients aus dem Internet verbinden können.

## Randbedingungen
- Alle Systeme werden in einem git-Repository gepflegt und entsprechend der Struktur
  aus dem vorherigen Artikel definiert.
- Das Deployment erfolgt über `nixos-rebuild`.
- Die gesamte finale Konfiguration kann unter
  [TODO_HIER_URL_EINFÜGEN](https://TODO_HIER_URL_EINFÜGEN) eingesehen werden. Die
  folgenden Kapitel enthalten lediglich relevante Ausschnitte.

## Implementierung
### Router
Neben den Standard-Konfigurationsdateien verfügt der Router aufgrund seiner höheren
Komplexität über eine separate Datei für die Firewallkonfiguration. Darin werden
neben nftables Definitionen und Sets auch die Regeln für die Weiterleitung von
Paketen (FORWARD) festgelegt.

Für eine bessere Übersichtlichkeit wird jede Netzwerkschnittstelle in einer eigenen
Datei konfiguriert. Neben der Schnittstellenkonfiguration mit ifstate werden dort
auch die Firewallregeln für INPUT und OUTPUT definiert. Dabei greifen wir auf die
in firewall.nix definierten Aliase zurück.
```mermaid
treeView-beta
    "hosts"
        "router"
            "configuration.nix"
            "disk-config.nix"
            "firewall.nix"
            "hardware-configuration.nix"
            "interfaces"
                "default.nix"
                "ens18-internet.nix"
                "ens19-svc.nix"
                "ens20-inf.nix"
                "ens21-dmz.nix"
                "wg0-mgnt.nix"
            "monitoring.nix"
            "networking.nix"
            "secrets.yml"
        "..."
    "..."
```

#### Interne Netzwerkschnittstelle

Eine interne Netzwerkschnittstelle sieht dann beispielsweise so aus:
```nix
# hosts/router/interfaces/ens20-inf.nix
let
  interface = "ens20";
in
{
  networking = {
    ifstate.settings.interfaces."${interface}" = {
      addresses = [ "192.168.1.1/24" ];
      alt-names = [ "inf" ];
      link = {
        state = "up";
        kind = "physical";
        address = "01:23:45:67:89:ab";
      };
    };
    nftables.tables.nixos-fw.content = ''
      chain input-allow {
        # ci/cd pipeline on build deploys this host
        iifname ${interface} ip saddr @build4 tcp dport 22 accept
        iifname ${interface} ip6 saddr @build6 tcp dport 22 accept
      }
    '';
  };
}
```

#### Firewall

In der Firewallkonfiguration finden sich dann die sets sowie Weiterleitungsregeln:
```nix
# hosts/router/firewall.nix
{
  networking.nftables.tables.nixos-fw.content = ''
    set build4 {
      type ipv4_addr
      elements = { 192.168.1.10 }
    }
    set build6 {
      type ipv6_addr
      elements = { fd00::192:168:1:10 }
    }

    # ...

    chain forward-allow {
      # build -> git, to get git repos
      ip saddr @build4 ip daddr @git4 tcp dport { 22, 443 } accept
      ip6 saddr @build6 ip6 daddr @git6 tcp dport { 22, 443 } accept

      # ...
    }
  '';
}
```

#### Wireguard

Der Wireguard Endpunkt benötigt verschiedene Secrets (Private Key, Preshared Key für
jeden Client) Diese werden über sops verwaltet, auf dem System als Datei bereitgestellt
und dann in ifstate mit `!include path` geladen.
```nix
# hosts/router/interfaces/wg0-mgnt.nix
{ config, ... }:
let
  interface = "wg0";
in
{
  sops.secrets = {
    "wireguard/priv" = { };
    "wireguard/psk/nico" = { };
    "wireguard/psk/luis" = { };
  };

  networking = {
    ifstate.settings.interfaces."${interface}" = {
      addresses = [ "192.168.4.1/24" ];
      link = {
        state = "up";
        kind = "wireguard";
      };
      wireguard = {
        private_key = "!include ${config.sops.secrets."wireguard/priv".path}";
        peers = {
          # nico
          "SMFlR8I+YU0iUhXRXfi9ig4phFlQJ64gonna1SrELmw=" = {
            preshared_key = "!include ${config.sops.secrets."wireguard/psk/nico".path}";
            allowedips = [ "192.168.4.2/32" ];
          };
          # luis
          "aJ8a8N0YAbY5iQTSWf52Fc4pStFfqPLp+BE0JV6fj3g=" = {
            preshared_key = "!include ${config.sops.secrets."wireguard/psk/luis".path}";
            allowedips = [ "192.168.4.3/32" ];
          };
        };
      };
    };

    nftables.tables.nixos-fw.content = ''
      chain input-allow {
        iifname ${interface} tcp dport 22 accept
      }
    '';
  };
}
```
Des Weiteren ist zu bedenken, dass der von Wiregaurd verwendete Port (hier: 51820)
aus dem Internet erreichbar sein muss. Dafür fügen wir in der Konfiguration der
Netzwerkschnittstelle ens18 eine Firewallregel ein, welche eingehende Anfragen
erlauben.

#### Internet
```nix
# hosts/router/interfaces/ens18-internet.nix
let
  interface = "ens18";
in
{
  networking = {
    ifstate.settings = {
      interfaces."${interface}" = {
        addresses = [ "192.168.0.2/24" ];
        alt-names = [ "internet" ];
        link = {
          state = "up";
          kind = "physical";
          address = "12:34:56:78:9a:bc";
        };
      };
      routing.routes = [
        {
          to = "0.0.0.0/0";
          via = "192.168.0.1";
        }
      ];
    };
    nftables.tables.nixos-fw.content =
      let
        wg0Port = toString config.networking.ifstate.settings.interfaces.wg0.listen_port;
      in
      ''
        chain input-allow {
          # wireguard
          iifname ${interface} ip daddr @routerPublic4 udp dport ${wg0Port} accept
          iifname ${interface} ip6 daddr @routerPublic6 udp dport ${wg0Port} accept
        }
      '';
  };
}
```
Hier nutzen wir einen der Vorteile von Nix: In der Konfiguration können wir auf andere Konfigurationselemente zugreifen.
Statt den Port statisch festzulegen, beziehen wir ihn über config aus der bestehenden Konfiguration. Ändert sich der Port,
muss er dadurch nur an einer Stelle angepasst werden.
