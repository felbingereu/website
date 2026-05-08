---
date:
  created: 2026-05-09
authors:
- nicof2000
readtime: 3
draft: true
---
# Linux Game Server Manager: Arma 3 Server: Exile Mod

Während sich der vorherige Post auf die Basisinstallation des Arma 3 Servers unter Linux bezog,
ergänzt dieser die Anleitung um die Installation der Exile Mod.

<!-- more -->

Zunächst wird der ExileServer Mod heruntergeladen und in den Serverfiles eingefügt:
```sh
wget -O /tmp/ExileServer-1.0.4a.zip http://exilemod.com/ExileServer-1.0.4a.zip
mkdir -p /tmp/ExileServer
unzip /tmp/ExileServer-1.0.4a.zip -d /tmp/ExileServer
rm /tmp/ExileServer-1.0.4a.zip

cp -r /tmp/ExileServer/Arma\ 3\ Server/* ~arma3server/serverfiles/
```

Die Exile Mod selbst kann nur über den Steam Workshop heruntergeladen werden, daher muss diese vom Client hochgeladen werden:
```sh
scp -r 'C:\Program Files (x86)\Steam\steamapps\workshop\content\107410\1487484880' root@{IP}:/home/arma3server/serverfiles/\@Exile
```

Anschließend noch die Berechtigungen anpassen:
```sh
chown -R arma3server:arma3server ~arma3server/serverfiles/\@Exile
```

Und die Mods laden:
```sh
cat <<_EOF >> ~arma3server/lgsm/config-lgsm/arma3server/arma3server.cfg
# mods="@Exile;@Extended_Base_Mod;@AdminToolkitServer"
mods="@Exile"
servermods="@ExileServer"
_EOF
```

## Serverkonfiguration
Die Mod stellt Arma 3 Serverkonfigurationen zur Verfügung, diese werden verschoben und angepasst:
```sh
mv ~arma3server/serverfiles/@ExileServer/basic.cfg ~arma3server/serverfiles/cfg/arma3server.network.cfg
mv ~arma3server/serverfiles/@ExileServer/config.cfg ~arma3server/serverfiles/cfg/arma3server.server.cfg 
sed -i \
  -e 's|hostname.*|hostname = "felbinger.eu";|g' \
  -e 's|passwordAdmin.*|passwordAdmin = "'r4nd0m-s3cr3t'";|g' \
  -e 's|serverCommandPassword.*|serverCommandPassword = "'r4nd0m-s3cr3t'";|g' \
  -e 's|maxPlayers.*|maxPlayers = 10;|g' \
  ~arma3server/serverfiles/cfg/arma3server.server.cfg
```

## Datenbank
Exile erfordert eine MySQL Datenbank.
```sh
apt-get install -y mariadb-server
mysql < /tmp/ExileServer/MySQL/exile.sql
sed -i 's/^Username = changeme/Username = root/' ~arma3server/serverfiles/@ExileServer/extdb-conf.ini
```

### extDB2
Zur Kommunikation mit dieser verwendet Exile Standardmäßig extDB2, welches lediglich als 32-bit Library verfügbar ist.
```sh
cat <<_EOF >> /etc/apt/sources.list
# oldoldstable for libtbb2 (extDB2)
deb http://archive.debian.org/debian/ bullseye main contrib non-free
_EOF

apt-get update
apt-get install -y libtbb2:i386

cat <<_EOF >> ~arma3server/lgsm/config-lgsm/arma3server/arma3server.cfg
# extDB2 is only for 32-bit
executable="./arma3server"
_EOF
```

<!-- TODO: ggf. geht das nicht mit root user?, ggf. Upgrade auf extDB3 erforderlich? -->

### extDB3
Alternativ zur Installation von extDB2 kann Exile auf extDB3 migriert werden:
```sh
git clone https://github.com/BrettNordin/Exile /tmp/exile
rm ~arma3server/serverfiles/@ExileServer/{extDB2\ LICENSE.txt,extDB2.so,xm8.so,extDB2.dll,XM8.dll}
cp -r /tmp/exile/@ExileServer/ ~arma3server/serverfiles/

# while mixing lowercase and uppercase is not a problem for windows, it is indeed for linux, so let's rename to all lowercase
mv ~arma3server/serverfiles/@ExileServer/addons/{Exile_Server_Overrides,exile_server_overrides}
mv ~arma3server/serverfiles/@ExileServer/addons/{Exile_Server_Overrides,exile_server_overrides}.pbo
```


## TODO
Server startet nicht: ExileServer - Server is loading..., Nonnetwork object c48ff700

<!--
weil es auf linux nicht geht hab ich es auf ws1 unter windows aufgesetzt
nach einigem hin und her läuft es nun.

Fürs Admin Toolkit:
@AdminToolitServer/addons/admintoolkit_servercfg.pbo mit pbomanager extrahieren und config.cpp bearbeiten (password + steam id)
Arma 3 Tools -> Addon Builder -> binarize aus (muss nicht, erleichtert aber debuggen)
Mission automatisch patchen ging nicht :(
Geld konnte man über die DB geben, genauso wie custom mod items (geht nicht über AdminToolKit)
-->

## Mod: Extended Base Mod (EBM)
tbd
<!--
untested
```sh
scp -r 'C:\Program Files (x86)\Steam\steamapps\workshop\content\107410\647753401' root@{IP}:/home/arma3server/serverfiles/\@EBM
```
```sh
sed -i (ADD MOD) ~arma3server/lgsm/config-lgsm/arma3server/arma3server.cfg
cp ~arma3server/serverfiles/\@EBM/keys/ExtendedBase3.5.bikey arma3server/serverfiles/keys/
TODO add EBM to mission pbo TODO how to unpack in linux?
```
see readme for whole tutorial
-->
## Mod: [AdminServerToolkit (ATK)](https://github.com/ole1986/a3-admintoolkit)
tbd

<!-- make sure to add stuff for exile https://github.com/ole1986/a3-admintoolkit/blob/master/source/mission_file/atk/README.ExileMod.md -->
