---
date:
  created: 2025-08-07
authors:
- nicof2000
readtime: 3
---
# Linux Game Server Manager: DayZ Server
<!--
TODO:
- Setup erneut durchführen, diesmal Steam Account ohne DayZ verwenden und Alternative Lösung in Issue 4601 anwenden.
	Wenn es funktioniert Blog-Eintrag anpassen.
-->

Ein Bekannter bat mich kürzlich, einen DayZ-Server mit dem VPP-Admin-Tool und DeerIsle aufzusetzen.
Für das Hosting entschied ich mich für einen vServer mit Debian 12 als Basis. Die Installation und
Verwaltung des Servers erledigte ich bequem mit dem Tool [Linux Game Server Managers (LGSM)]([Linux Game Server Managers (LGSM)](https://linuxgsm.com/)),
das speziell für dedizierte Game-Server unter Linux entwickelt wurde.

<!-- more -->

## Steam Account

Für den Download der Serverdateien von Steam wird ein Steam-Account benötigt. Üblicherweise erstellt
man dafür einen separaten Account, um die eigenen Zugangsdaten nicht zu gefährden – diese liegen auf
dem Server nämlich im Klartext.

Beim DayZ-Server führt ein solcher „frischer“ Account jedoch zu Problemen: Hat der Account DayZ nicht
gekauft, wird der Server zwar installiert und gestartet, jedoch unvollständig – es fehlen unter anderem
die offiziellen Missionen. Dieses Verhalten wurde bereits in [Issue #4601](https://github.com/GameServerManagers/LinuxGSM/issues/4601)
bei LGSM dokumentiert.

Zur Lösung dieses Problems gibt es zwei Ansätze:
1. Die fehlenden Missionen manuell über das offizielle
   [GitHub-Repository von Bohemia Interactive](https://github.com/BohemiaInteractive/DayZ-Central-Economy) nachladen.
2. Einen Steam-Account verwenden, der DayZ besitzt – wie es ein
   [Nutzer](https://github.com/GameServerManagers/LinuxGSM/issues/4601#issuecomment-2683274938) ebenfalls vorschlägt.

Ich entschied mich für die zweite Variante, um mögliche Folgeprobleme zu vermeiden. Dafür habe ich meine
eigenen Steam-Zugangsdaten temporär auf dem Server hinterlegt. Nachdem ich die bestehenden Serverdateien
gelöscht und den SteamCMD-Login via Steam Guard bestätigt hatte, wurden alle Dateien – inklusive der
Missionen – vollständig heruntergeladen.

## Basisinstallation
```sh
apt-get install -y curl jq nano git

# siehe https://linuxgsm.com/servers/dayzserver/
adduser dayzserver # TODO PASSWORD
su - dayzserver # run cmds seprate
curl -Lo linuxgsm.sh https://linuxgsm.sh && chmod +x linuxgsm.sh && bash linuxgsm.sh dayzserver
cat <<_EOF >> ~dayzserver/lgsm/config-lgsm/dayzserver/secrets-dayzserver.cfg
steamuser=
steampass=
_EOF
```
Zunächst wird das install-Kommando einmalig als root ausgeführt, um fehlende Abhängigkeiten zu installieren.
Danach erfolgt die eigentliche Serverinstallation als der zuvor angelegte, nicht-privilegierte Benutzer:
```sh
# wieder zurück von su shell in root shell
exit
./dayzserver install

# anschließend als dayzserver nutzer
su - dayzserver
./dayzserver install
```

Die Konfiguration des Servers erfolgt in der Datei `~dayzserver/serverfiles/cfg/dayzserver.server.cfg`. Ich
passte zunächst folgende Einstellungen direkt per sed an:
```sh
sed -i \
  -e 's|hostname.*|hostname = "felbinger.eu";|g' \
  -e 's|passwordAdmin.*|passwordAdmin = "'r4nd0m-s3cr3t'";|g' \
  -e 's|maxPlayers.*|maxPlayers = 10;|g' \
  -e 's|disable3rdPerson.*|disable3rdPerson = 1;|g' \
  -e 's|disableCrosshair.*|disableCrosshair = 1;|g' \
  ~dayzserver/serverfiles/cfg/dayzserver.server.cfg
```

Nun kann der Server mit dem Befehl `./dayzserver start` gestartet wurde. Die Konsole des DayZ Servers steht in
einer tmux-Session zur Verfügung, die vereinfacht mit `./dayzserver console` geöffnet werden kann.

Ich konnte dem Server im Anschluss erfolgreich über den DayZ Launcher (unter Servers → Direct Connection) beitreten.

## Mods
### CF & VPPAdminTools
Im nächsten Schritt stand die Installation der benötigten Mods an.
Den Anfang machte das gewünschte Admin-Werkzeug: das VPP-Admin-Tool.

Die Entwickler stellen im [offiziellen Wiki](https://github.com/VanillaPlusPlus/VPP-Admin-Tools/wiki/Installation-&-Configuration)
eine ausführliche Anleitung für die Installation und Konfiguration auf dedizierten Servern zur Verfügung.

Die benötigten Mods – insbesondere CF (eine Basisabhängigkeit vieler Mods) und VPPAdminTools selbst – wurden zunächst auf dem Client
über den Steam Workshop heruntergeladen. Anschließend kopierte ich sie manuell auf den Server in das entsprechende serverfiles-Verzeichnis.

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

Anschließend mussten die Signaturdateien (BIKeys) der verwendeten Mods in das Serververzeichnis kopiert werden.
Nur so erkennt der Server die Mods als gültig und erlaubt es den Clients, sich mit aktivierten Mods zu verbinden.
```sh
# cp ~dayzserver/serverfiles/@CF/keys/Jacob_Mango_V3.bikey ~dayzserver/serverfiles/keys/
# cp ~dayzserver/serverfiles/@VPPAdminTools/keys/VPP.bikey ~dayzserver/serverfiles/keys/
```

Zuletzt wurden die Mods dauerhaft in die Serverkonfiguration eingebunden. Dafür ergänzte ich zunächst die
`dayzserver.cfg` im LGSM-Konfigurationsverzeichnis um den entsprechenden mods-Eintrag:
```sh
cat <<_EOF >> ~dayzserver/lgsm/config-lgsm/dayzserver/dayzserver.cfg
mods="@CF\;@VPPAdminTools"
_EOF
```

Nach einem Neustart des Servers sollte nun automatisch im Profilverzeichnis unter
`~dayzserver/.local/share/DayZ Other Profiles/Server` die Konfiguration für das
VPP-Admin-Tool erstellt werden, die für die weitere Konfiguration entscheidend ist.

Da diese Konfigurationsdateien nicht generiert wurden, entschied ich mich, das
Profilverzeichnis manuell über die Startparameter zu setzen. In diesem Fall musste
ich allerdings auch die Mods direkt über den -mod-Parameter angeben, da die zuvor
gesetzte mods-Variable nicht mehr ausgewertet wurde:

```sh
cat <<_EOF >> ~dayzserver/lgsm/config-lgsm/dayzserver/dayzserver.cfg
startparameters="-ip=${ip} -port=${port} -config=${servercfgfullpath} -profiles=profiles -mod=@CF\;@VPPAdminTools -servermod=${servermods} -bepath=${bepath} -limitFPS=60 -dologs -adminlog -freezeCheck"
_EOF
# mods variable is no longer in use
sed -i '/mods.*/d' ~dayzserver/lgsm/config-lgsm/dayzserver/dayzserver.cfg
```

Nachdem ich mit `mkdir ~dayzserver/serverfiles/profiles` das Verzeichnis erstellt hatte und den Server neu
startete, wurden die Konfigurationsdateien für das VPP-Admin-Tool wie erwartet generiert. Um einen Spieler
als Administrator einzutragen, wird dessen SteamID64 benötigt. Diese lässt sich auf zwei Wegen ermitteln:
1. Während der Spieler dem Server beitritt, erscheint seine Steam-ID im Server-Log.
2. Alternativ kann die ID über [steamidfinder.com](https://www.steamidfinder.com/) aus dem Steam-Benutzernamen
   oder der Profil-URL ermittelt werden. Die benötigte ID steht im Feld steamID64.

Mehrere Administratoren können definiert werden, indem in der Datei `SuperAdmins.txt` pro Zeile eine Steam-ID
eingetragen wird. Außerdem ist ein Passwort erforderlich, das die berechtigten Nutzer beim Öffnen des Tools im
Spiel eingeben müssen.

```sh
echo adminUid > ~dayzserver/serverfiles/profiles/VPPAdminTools/Permissions/SuperAdmins/SuperAdmins.txt
echo adm1n-s3cr3t > ~dayzserver/serverfiles/profiles/VPPAdminTools/Permissions/credentials.txt
```
Nach einem weiteren Neustart des Servers (`~dayzserver/dayzserver restart`) konnte das VPP-Admin-Tool im Spiel
wie erwartet verwendet werden – nach Eingabe des festgelegten Passworts hatte der konfigurierte Benutzer Zugriff
auf alle administrativen Funktionen.

### DeerIsle
Der DeerIsle Mod wurde ebenfalls vom Client heruntergeladen und in das Verzeichnis
`~dayzserver/serverfiles/@DeerIsle` hochgeladen. Die beiden benötigten Signing Keys kopierte ich anschließend mit:
```sh
cp ~dayzserver/serverfiles/@DeerIsle/keys/* ~dayzserver/serverfiles/keys/
```

In der Serverkonfiguration `~dayzserver/lgsm/config-lgsm/dayzserver/dayzserver.cfg` wurden die "startparameters" entsprechend
angepasst, um den Mod zusätzlich zu laden (`-mod=@CF\;@VPPAdminTools\;@DeerIsle`).

Um die eigentliche Mission zu installieren, klonte ich das offizielle Repository,
verschob die Missionsdatei und passte die Serverkonfiguration an:
```sh
git clone https://github.com/johnmclane666/Deerisle-Stable
mv Deerisle-Stable/V5.9/empty.deerisle ~dayzserver/serverfiles/mpmissions
rm -r Deerisle-Stable
sed -i 's/template.*/template = "empty.deerisle";/' ~dayzserver/serverfiles/cfg/dayzserver.server.cfg
```

Damit war die DeerIsle-Mission auf dem Server einsatzbereit.

## Spawn-Loadout
Abschließend wurde die Mission so angepasst, dass das Spawn-Loadout der Spieler verändert wird.
Dazu wurde die unten stehende C-Funktion in der Datei `~dayzserver/serverfiles/mpmission/empty.deerisle/init.c` modifiziert.
```c
  override void StartingEquipSetup(PlayerBase player, bool clothesChosen)
  {
    player.RemoveAllItems();

    // Military Uniform and Boots
    EntityAI boots, knife;
    player.GetInventory().CreateInInventory("TTsKOJacket_Camo");
    player.GetInventory().CreateInInventory("TTSKOPants");
    player.GetInventory().CreateInInventory("TacticalGloves_Green");
    boots = player.GetInventory().CreateInInventory("MilitaryBoots_Brown");
    knife = boots.GetInventory().CreateInInventory("CombatKnife");
    player.SetQuickBarEntityShortcut(knife, 3); // Add to quick bar

    // Tactial Helmet with NVG and Flashlight
    //EntityAI helmet, helmetAttachment;
    //helmet = player.GetInventory().CreateInInventory("Mich2001Helmet");
    //helmetAttachment = helmet.GetInventory().CreateAttachment("UniversalLight");
    //helmetAttachment.GetInventory().CreateAttachment("Battery9V");
    //helmetAttachment = helmet.GetInventory().CreateAttachment("NVGoggles");
    //helmetAttachment.GetInventory().CreateAttachment("Battery9V");

    // Belt with Knife and fully equiped Pistol
    EntityAI belt, beltHolster, beltPistol, beltPistolAttachment;
    belt = player.GetInventory().CreateInInventory("MilitaryBelt");
    belt.GetInventory().CreateInInventory("Canteen");
    //beltHolster = belt.GetInventory().CreateInInventory("NylonKnifeSheath");
    //beltHolster.GetInventory().CreateInInventory("CombatKnife");
    beltHolster = belt.GetInventory().CreateInInventory("PlateCarrierHolster");
    beltPistol = beltHolster.GetInventory().CreateInInventory("Glock19");
    player.SetQuickBarEntityShortcut(beltPistol, 1); // Add to quick bar
    beltPistol.GetInventory().CreateAttachment("Mag_Glock_15Rnd");
    //beltPistol.GetInventory().CreateAttachment("PistolSuppressor");
    //beltPistolAttachment = beltPistolAttachment.GetInventory().CreateAttachment("FNP45_MRDSOptic");
    //beltPistolAttachment.GetInventory().CreateAttachment("Battery9V");
    //beltPistolAttachment = beltPistolAttachment.GetInventory().CreateAttachment("TLRLight");
    //beltPistolAttachment.GetInventory().CreateAttachment("Battery9V");
    player.GetInventory().CreateInInventory("Mag_Glock_15Rnd");
    player.GetInventory().CreateInInventory("Ammo_9x19");

    // Plate Carrier
    //EntityAI vest, pouches, vestHolster, vestPistol;
    //vest = player.GetInventory().CreateInInventory("PlateCarrierVest");
    //vestHolster = vest.GetInventory().CreateAttachment("PlateCarrierHolster");
    //vestPistol = vestHolster.GetInventory().CreateInInventory("Magnum");
    //player.SetQuickBarEntityShortcut(vestPistol, 2); // Add to quick bar
    //pouches = vest.GetInventory().CreateAttachment("PlateCarrierPouches");
    //pouches.GetInventory().CreateInInventory("Ammo_357");

    player.GetInventory().CreateInInventory("BandageDressing");
    player.GetInventory().CreateInInventory("BandageDressing");

    EntityAI itemEnt;
    string chemlightArray[] = {
      "Chemlight_White",
      "Chemlight_Yellow",
      "Chemlight_Green",
      "Chemlight_Red"
    };
    int rndIndex = Math.RandomInt( 0, 4 );
    itemEnt = player.GetInventory().CreateInInventory( chemlightArray[rndIndex] );
    SetRandomHealth( itemEnt );

    float rand = Math.RandomFloatInclusive( 0.0, 1.0 );
    if ( rand < 0.35 )
      itemEnt = player.GetInventory().CreateInInventory( "Apple" );
    else if ( rand > 0.65 )
      itemEnt = player.GetInventory().CreateInInventory( "Pear" );
    else
      itemEnt = player.GetInventory().CreateInInventory( "Plum" );
    SetRandomHealth( itemEnt );
  }
```
Die verwendeten Classnames für die Items können online eingesehen werden, beispielsweise [hier](https://github.com/CypherMediaGIT/DayZClassNames2020/blob/master/classname2020).
