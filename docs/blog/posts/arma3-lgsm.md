---
date:
  created: 2026-05-08
authors:
- nicof2000
readtime: 3
---
# Linux Game Server Manager: Arma 3 Server

Dieser Blog Post beschreibt die Installation eines Arma 3 Exile Servers auf einem vServer
mit Debian 13 und [Linux Game Server Managers (LGSM)](https://linuxgsm.com/).

<!-- more -->

## Steam Account

Für den Download der Serverdateien von Steam wird ein Steam-Account benötigt.
Da die Zugangsdaten im Klartext auf dem Server abgelegt werden müssen, empfielt
sich die Erstellung eines separaten Steam Accounts.

## Basisinstallation
```sh
apt-get install -y curl jq nano git

# siehe https://linuxgsm.com/servers/arma3server/
adduser --disabled-password --gecos "" arma3server
su - arma3server # run cmds seprate
curl -Lo linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && bash linuxgsm.sh arma3server
mkdir -p ~arma3server/lgsm/config-lgsm/arma3server/
cat <<_EOF >> ~arma3server/lgsm/config-lgsm/arma3server/secrets-arma3server.cfg
steamuser=
steampass=
_EOF
./arma3server install
```
Nachdem die erste Ausführung des Install-Befehls, die Verzeichnisstruktur angelegt hat, ist feststellbar,
dass diverse Abhängigkeiten nicht installiert sind. Der Einfachste weg diese zu installieren ist es
diesen Befehl erneut als root-Nutzer auszuführen. Danach erfolgt die eigentliche Serverinstallation als
der zuvor angelegte, nicht-privilegierte Benutzer:
```sh
# wieder zurück von su shell in root shell
exit
~arma3server/arma3server install

# anschließend als arma3server nutzer
su - arma3server
./arma3server install
```

Die Konfiguration des Servers erfolgt in der Datei `~arma3server/serverfiles/cfg/arma3server.server.cfg`.
```sh
sed -i \
  -e 's|hostname.*|hostname = "felbinger.eu";|g' \
  -e 's|passwordAdmin.*|passwordAdmin = "'r4nd0m-s3cr3t'";|g' \
  -e 's|maxPlayers.*|maxPlayers = 10;|g' \
  ~arma3server/serverfiles/cfg/arma3server.server.cfg
```

Nun kann der Server mit dem Befehl `./arma3server start` gestartet wurde. Die Konsole des Servers
steht in einer tmux-Session zur Verfügung, die mit `./arma3server console` geöffnet werden kann.

Für die Installation von Mods wie Exile werden weitere Blog Posts folgen.
