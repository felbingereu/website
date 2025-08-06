---
date:
  created: 2025-08-06
authors:
- nicof2000
readtime: 3
draft: true
---
# Linux Game Server Manager: DayZ Server

Ich wurde von einem Bekannten gebeten einen DayZ Server mit dem VPP-Admin-Tool
und der DayZ DeerIsle Mission bereitzustellen. Dazu verwendete ich einen v-Server
mit Debian 12 auf dem ich diesen mittels [Linux Game Server Managers (LGSM)](https://linuxgsm.com/) installierte.

---

## Steam Account

Für den Download der Serverdateien von Steam ist ein Steam Account erforderlich. Für
gewöhnlich erstellt man hierfür einen neuen Steam Account, um seinen eigenen Account
keinen unnötigen Gefahren (Zugangsdaten liegen auf dem Server im Klartext) auszusetzen.

Im Falle des DayZ Servers führt die erstellung eines neuen Accounts (der DayZ nicht besitzt), zu
einem unvollstädigen Download. Zwar startet der Server, allerdings fehlen die Missionen für DayZ.
Dies wurde bei LGSM auch bereits in [Issue #4601](https://github.com/GameServerManagers/LinuxGSM/issues/4601)
dokumentiert.

Um dieses Problem zu lösen, gibt es zwei Ansätze. Zum einen kann die Mission aus dem offiziellen
[Git-Repository von Bohemia Interactive](https://github.com/BohemiaInteractive/DayZ-Central-Economy)
nachgeladen werden. Alternativ schreibt ein [Nutzer](https://github.com/GameServerManagers/LinuxGSM/issues/4601#issuecomment-2683274938),
sei die Verwendung eines Accounts der DayZ besitzt möglich.

Ich entschied mich für letzteren Lösungsansatz, da dieser weiteren Probleme verhindern sollte und hinterlegte
meine eigenen Steam Zugangsdaten auf dem Server. Nachdem ich die Serverfiles gelöscht hatte und den Login der
SteamCMD in der Steam App (aktivierte Steam Guard) bestätigt hatte, wurden die vollständigen Serverfiles
heruntergeladen.

## Basisinstallation
```sh
apt-get install -y curl jq nano

# siehe https://linuxgsm.com/servers/dayzserver/
adduser dayzserver # TODO PASSWORD
su - dayzserver # run cmds seprate
curl -Lo linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && bash linuxgsm.sh dayzserver
cat <<_EOF >> ~dayzserver/lgsm/config-lgsm/dayzserver/secrets-dayzserver.cfg
steamuser=
steampass=
_EOF

# zunächst als root, um abhängigkeiten zu installieren
./dayzserver install

# anschließend als low privileged user zur installation des dayz servers
./dayzserver install
```

Danach kann die Konfiguration des DayZ Servers selbst in der Datei
`~dayzserver/serverfiles/cfg/dayzserver.server.cfg` angepasst werden.

Zunächst wurden dabei folgende Einstellungen angepasst:
```sh
sed -i \
  -e 's|hostname.*|hostname = "felbinger.eu";|g' \
  -e 's|passwordAdmin.*|passwordAdmin = "'r4nd0m-s3cr3t'";|g' \
  -e 's|disable3rdPerson.*|disable3rdPerson = 1;|g' \
  -e 's|disableCrosshair.*|disableCrosshair = 1;|g' \
  ~dayzserver/serverfiles/cfg/dayzserver.server.cfg
```

Nachdem der Server mit dem Befehl `./dayzserver start` gestartet wurde,
ist der Aufruf der tmux-Session mit der Serverkonsole über den Befehl
`./dayzserver console` möglich.

Abschließend wurde Versucht dem DayZ Server über den DayZ Launcher
(Servers -> Direct Connection) beizutreten, was erfolgreich war.

## Mods
### CF & VPPAdminTools
Im nächsten Schritt mussten die benötigten Mods auf dem Server installiert werden.

Zunächst konzentrierte ich mich hierbei auf das gewünschte Admin Toolkit (VPP-Admin-Tool),
dessen [Wiki](https://github.com/VanillaPlusPlus/VPP-Admin-Tools/wiki/Installation-&-Configuration)
eine ausführliche Installationsanleitung für dedizierte Server beinhaltet.

Die Mods wurden vom Client aus, aus dem Steam Workshop heruntergeladen und auf den Server kopiert.

```sh
# ls -l ~dayzserver/serverfiles
total 60352
drwxr-xr-x 1 dayzserver dayzserver    11900 Aug  6 19:09 addons
-rwxr-xr-x 1 dayzserver dayzserver      637 Aug  6 19:08 ban.txt
drwxr-xr-x 1 dayzserver dayzserver       70 Aug  6 19:09 battleye
drwxr-xr-x 1 dayzserver dayzserver       50 Aug  6 19:21 @CF              # <---
drwxr-xr-x 1 dayzserver dayzserver       42 Aug  6 19:11 cfg
-rwxr-xr-x 1 dayzserver dayzserver     1956 Aug  6 19:08 dayz.gproj
-rwxr-xr-x 1 dayzserver dayzserver 23222512 Aug  6 19:08 DayZServer
-rwxr-xr-x 1 dayzserver dayzserver     1106 Aug  6 19:08 dayzsetting.xml
drwxr-xr-x 1 dayzserver dayzserver       48 Aug  6 19:33 docs
drwxr-xr-x 1 dayzserver dayzserver      474 Aug  6 19:09 dta
drwxr-xr-x 1 dayzserver dayzserver      144 Aug  6 19:37 keys
-rwxr-xr-x 1 dayzserver dayzserver   391056 Aug  6 19:08 libsteam_api.so
drwxr-xr-x 1 dayzserver dayzserver      120 Aug  6 19:09 mpmissions
drwxr-xr-x 1 dayzserver dayzserver       12 Aug  6 19:09 sakhal
-rwxr-xr-x 1 dayzserver dayzserver     3165 Aug  6 19:08 serverDZ.cfg
drwxr-xr-x 1 dayzserver dayzserver      200 Aug  6 19:09 server_manager
-rwxr-xr-x 1 dayzserver dayzserver        6 Aug  6 19:08 steam_appid.txt
drwxr-xr-x 1 dayzserver dayzserver       74 Aug  6 19:09 steamapps
-rwxr-xr-x 1 dayzserver dayzserver 38156120 Aug  6 19:08 steamclient.so
drwxr-xr-x 1 dayzserver dayzserver       50 Aug  6 19:32 @VPPAdminTools    # <---
-rwxr-xr-x 1 dayzserver dayzserver      766 Aug  6 19:08 whitelist.txt
```

Danach wurden die Signing Keys in das DayZ Serververzeichnis kopiert, sodass die Mods auch Clientseitig geladen werden können:
```sh
# cp ~dayzserver/serverfiles/@CF/keys/Jacob_Mango_V3.bikey ~dayzserver/serverfiles/keys/
# cp ~dayzserver/serverfiles/@VPPAdminTools/keys/VPP.bikey ~dayzserver/serverfiles/keys/
```

Zuletzt wurden die Mods zum Startbefehl hinzugefügt.
```sh
cat <<_EOF >> ~dayzserver/lgsm/config-lgsm/dayzserver/dayzserver.cfg
mods="@CF\;@VPPAdminTools"
_EOF
```

Nach einem Neustart des Servers sollte nun im Profilverzeichnis
(`~dayzserver/.local/share/DayZ Other Profiles/Server`) die Konfiguration
des VPP-Admin-Tools generiert werden, in die dann die erlaubten Nutzer des
Tools eingetragen werden.

Nach dem Neustart ist feststellbar, dass die Mods korrekt geladen werden und das Beitreten
des Servers nun diese beiden Mods erfordert. Die zur Konfiguration notwendigen Dateien wurden
allerdings nicht im Server Profil generiert.

<!-- TODO: anleitung nochmal lesen und nachmachen -->

### DeerIsle
<!-- TODO: DeerIsle hinzufügen -->

## Anpassung des Spawn-Loadouts
<!-- TODO: mpmisions initialconfiguration anpassen (classnames) -->
