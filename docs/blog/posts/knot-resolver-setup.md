---
date:
  created: 2025-03-10
authors:
- nicof2000
readtime: 5
categories:
- NixOS
---

# Aufsetzen eines Knot Resolvers

Letztes Wochenende habe ich auf einem System Knot Resolver ausgerollt.
Meine Absicht war es, einen dnsmasq zu ersetzen, um DNS over TLS (DoT)
zu implementieren. dnsmasq hatte in meinem Setup mehrere Funktionen:
dnsmasq überschieb bestimmte Adressen, blockierte Werbung und leitete
bestimmte Zonen an andere DNS-Server weiter. Knot Resolver sollte all
diese Aufgaben übernehmen.

<!-- more -->

## Was ist Knot Resolver
Knot Resolver ist ein moderner, hochgradig anpassbarer rekursiver DNS-Resolver,
der für Flexibilität und Sicherheit entwickelt wurde. Er bietet Features wie
DNS over TLS (DoT), DNS over HTTPS (DoH), Caching, Policy-basiertes Routing und
eine Lua-Skript-Engine zur individuellen Anpassung. Im Gegensatz zu dnsmasq, das
primär als lokaler DNS-Cache für kleine Netzwerke gedacht ist, ist Knot Resolver
leistungsfähiger und bietet erweiterte Debugging- und Routing-Möglichkeiten.

## Einrichtung
Im folgenden wird nun Schritt für Schritt die alte dnsmasq Konfiguration ersetzt:
```nix
{
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    alwaysKeepRunning = true;
    settings = {
      no-hosts = true;
      no-resolv = true;
      server = [
        "1.1.1.1"
        "1.0.0.1"
        "8.8.8.8"
        "8.8.4.4"
        "2606:4700:4700::1111"
        "2606:4700:4700::1001"
        "2001:4860:4860::8888"
        "2001:4860:4860::8844"

        "/example.net/10.20.40.2"
        "/example.org/10.20.40.2"
        "/example.net/10.20.40.3"
        "/example.org/10.20.40.3"
        "/example.de/10.20.35.1"
      ];
      address = [
        "/notebook.example.com/10.20.30.100"
      ];
      # block known ads
      "conf-file" = builtins.fetchurl {
        url = "https://raw.githubusercontent.com/notracking/hosts-blocklists/master/dnsmasq/dnsmasq.blacklist.txt";
        sha256 = "sha256:1v2jmwv0887i3civmh06s6bzrbkvr78m3icdr8dhy4aq75km6k1k";
      };
    };
  };
}
```

### DNS over TLS
Folgende Regeln implementieren DoT
```lua
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
```
Hierfür muss knot-resolver ausgehenden Traffic über Port tcp/853 senden dürfen.

### AdBlocking
```nix
let
  adblock-rpz = builtins.fetchurl {
    url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/multi.txt";
    sha256 = "sha256:1qvac9rkypdqc3mrz33mpqhzk1vhcj00dqbjhs43vd009nxm2pal";
  };
in ''
  policy.add(policy.rpz(policy.DENY_MSG('Blocked Ads'), '${adblock-rpz}', false))
'';
```

### Überschreiben einzelner Adressen
```lua
policy.add(policy.domains(policy.ANSWER(
  { [kres.type.A] = { rdata=kres.str2ip('10.20.30.100') } }
), { todname('notebook.example.com') }))
```

### Weiterleiten von DNS Anfragen an anderen Nameserver
Nach möglichkeit sollte immer `policy.FORWARD` verwendet werden, um DNSSEC zu validieren:
```lua
policy.add(policy.suffix(policy.FORWARD({'10.20.40.2', '10.20.40.3'}), policy.todnames({'example.net', 'example.org'})))
policy.add(policy.suffix(policy.STUB('10.20.35.1'), {todname('example.de')}))
```

### Zusammengefasst als Nix Konfiguration
```nix
{
  services.kresd = {
    enable = true;
    listenPlain = [
      "127.0.0.1:53"
      "[::1]:53"
      "10.20.30.1:53"
    ];
    listenTLS = [
      # internal DoT listener
      "10.20.30.1:853"
    ];
    extraConfig =
      let
        adblock-rpz = builtins.fetchurl {
          url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/rpz/multi.txt";
          sha256 = "sha256:1qvac9rkypdqc3mrz33mpqhzk1vhcj00dqbjhs43vd009nxm2pal";
        };
      in
      ''
        -- certificates for internal DoT listener, will be aquired via acme (out of scope for this blog entry)
        net.tls("/var/lib/acme/router.example.com/fullchain.pem", "/var/lib/acme/router.example.com/key.pem")

        -- handle internal domains
        policy.add(policy.suffix(policy.FLAGS({'NO_CACHE'}), policy.todnames({
          'example.net',
          'example.org',
          'example.de',
        })))
        policy.add(policy.suffix(policy.FORWARD({'10.20.40.2', '10.20.40.3'}), policy.todnames({'example.net', 'example.org'})))
        -- zone not signed using dnssec yet
        policy.add(policy.suffix(policy.STUB('10.20.35.1'), {todname('example.de')}))

        -- rewrite internal hosts
        policy.add(policy.domains(policy.ANSWER(
          { [kres.type.A] = { rdata=kres.str2ip('10.20.30.100') } }
        ), { todname('notebook.example.com') }))

        -- block known ads using rpz
        policy.add(policy.rpz(policy.DENY_MSG('Blocked Ads'), '${adblock-rpz}', false))

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
}
```

## Debugging
Während der Einrichtung hatte ich mehrfach Probleme, dass Regeln nicht die erwünschte
Wirkung erzielten. Folgende Regeln können hinzugefügt werden um die Anfragen zu Loggen:
```lua
policy.add(policy.all(policy.DEBUG_ALWAYS))
```
Da diese Regel das Debugging für alle Anfragen aktiviert, und sehr viele Logeinträge
produziert, ist es sinnvoller, das Logging auf eine bestimmte Zone zu beschränken:
```lua
policy.add(policy.suffix(policy.DEBUG_ALWAYS, policy.todnames({'example.net'})))
```

## Besondere Stolperfall: `policy.todnames` vs. `todnames`

Einige Funktionen erwarten, dass alle Domainnamen als Tabelle übergeben werden, während
andere für einzelne Domains auch einen String akzeptieren (siehe [Dokumentation](https://knot-resolver.readthedocs.io/en/stable/modules-policy.html#policy.FORWARD)).

Wird eine Tabelle als Übergabeparameter (wie beispielsweise bei 
`policy.suffix(action, suffix_table)`) erwartet, muss diese mit
`policy.todnames({'example.net'})` oder `{ todname('example.net') }` generiert werden.

