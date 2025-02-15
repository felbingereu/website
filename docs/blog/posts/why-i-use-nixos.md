---
date:
  created: 2025-02-15
authors:
- nicof2000
readtime: 5
categories:
- NixOS
---

# Warum ich NixOS nutze

Mein Weg zu NixOS war keine spontane Entscheidung, sondern das Ergebnis jahrelanger Erfahrungen
mit verschiedenen Linux-Distributionen. Ich habe früh angefangen, alternative Betriebssysteme
auszuprobieren, und hatte immer den Anspruch, mein System möglichst effizient, stabil und
flexibel zu gestalten. Doch erst mit NixOS habe ich eine Lösung gefunden, die meine Anforderungen
wirklich erfüllt.

<!-- more -->

Wie viele andere bin ich mit klassischen Linux-Distributionen gestartet. Zunächst nutzte ich Linux
Mint, weil es eine benutzerfreundliche Umgebung bot und einen einfachen Einstieg in die Linux-Welt
ermöglichte. Später wechselte ich zu Fedora, um Erfahrung im Bereich von RHEL-ähnlichen Systemen zu
erlangen. Beide Systeme haben gut funktioniert, aber mit der Zeit wurde mir bewusst, dass traditionelle
Paketmanager und Konfigurationsansätze einige Schwächen haben - insbesondere in Bezug auf
Reproduzierbarkeit und Wartbarkeit.

Um meine Systeme dennoch effizient einrichten zu können, schrieb ich in dieser Zeit Post-Install-Skripte.
Diese ermöglichten es mir, nach einer frischen Installation schnell alle benötigten Programme, Konfigurationen
und Anpassungen vorzunehmen. Dies sparte mir viel Zeit, war aber dennoch nicht ideal, da es immer wieder
Anpassungen und manuelle Eingriffe erforderte.

<details>
  <summary>Post-Install Skript für Fedora</summary>
  ```shell
  #!/bin/bash

  ###############################
  ##                           ##
  ##   Configuration Section   ##
  ##                           ##
  ###############################
  DNF_PACKAGES=(
    ## required packages for this post install script ##
    dnf-plugins-core
    distribution-gpg-keys
    ImageMagick
    terminator                                           # splitable terminal
    timeshift
    ## end of required packages ##

    keepassxc                                            # kdbx compatible password manager
    syncthing
    sqlitebrowser                                        # simple browser for sqlite databases
    remmina remmina-plugins-{vnc,rdp,www,spice,secret}   # remote access
    squashfs-tools
    VirtualBox
    audacity
    vlc                                                  # videolan: vlc media player
    totem                                                # gnome video player
    gimp
    flameshot                                            # tool to create and modify screenshots
    binwalk                                              # tool to analyse binary files for embeded files and executable code
    nmap
    gobuster                                             # directory and vhost enumeration
    wireshark
    texlive-scheme-full
    texstudio
    kubernetes-client
    ansible

    # yubikey utilities
    yubikey-personalization-gui
    yubikey-manager-qt
    yubico-piv-tool

    code                                                 # visual studio code using microsoft repo
    anydesk                                              # using anydesk (rhel) repo
    teamviewer                                           # using teamviewer repo
    brave-browser                                        # using brave repo
    signal-desktop                                       # from dnf copr
    android-tools

    gnome-tweaks
    gnome-extensions-app
    file-roller nemo-fileroller
    nemo                                                 # install nemo, so we have an alternative to nautilus
    nemo-seahorse                                        # nemo seahorse integration (sign / encrypt)
    xed
  )
  FLATPAK_PACKAGES=(
    im.riot.Riot                                         # Element Client
    com.spotify.Client
    org.ferdium.Ferdium
    org.gtk.Gtk3theme.Adwaita-dark
  )

  ###################################
  ##                               ##
  ##   Create Repo Files Section   ##
  ##                               ##
  ###################################
  mkdir -p /tmp/repos.d
  cat <<_EOF >> /tmp/repos.d/anydesk.repo
  [anydesk]
  name=AnyDesk RHEL - stable
  baseurl=http://rpm.anydesk.com/rhel/x86_64/
  gpgcheck=1
  repo_gpgcheck=1
  gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
  _EOF
  cat <<_EOF >> /tmp/repos.d/teamviewer.repo
  [teamviewer]
  name=TeamViewer - \$basearch
  baseurl=https://linux.teamviewer.com/yum/stable/main/binary-\$basearch/
  gpgkey=https://linux.teamviewer.com/pubkey/currentkey.asc
  gpgcheck=1
  repo_gpgcheck=1
  enabled=1
  type=rpm-md
  _EOF
  cat <<_EOF >> /tmp/repos.d/vscode.repo
  [code]
  name=Visual Studio Code
  baseurl=https://packages.microsoft.com/yumrepos/vscode
  enabled=1
  gpgcheck=1
  gpgkey=https://packages.microsoft.com/keys/microsoft.asc
  _EOF

  #################################
  ##                             ##
  ##   Install Package Section   ##
  ##                             ##
  #################################
  sudo dnf update -y --refresh

  # add fusion repositories
  sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

  ## check if packages in configuration, which require pre install commands ##
  [[ ${DNF_PACKAGES[@]} =~ "code" ]] && (
    sudo mv /tmp/repos.d/vscode.repo /etc/yum.repos.d/vscode.repo
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  )

  [[ ${DNF_PACKAGES[@]} =~ "anydesk" ]] && (
    sudo mv /tmp/repos.d/anydesk.repo /etc/yum.repos.d/anydesk.repo
    sudo rpm --import https://keys.anydesk.com/repos/RPM-GPG-KEY
  )

  [[ ${DNF_PACKAGES[@]} =~ "teamviewer" ]] && (
    sudo mv /tmp/repos.d/teamviewer.repo /etc/yum.repos.d/teamviewer.repo
    sudo rpm --import https://linux.teamviewer.com/pubkey/currentkey.asc
  )

  [[ ${DNF_PACKAGES[@]} =~ "brave-browser" ]] && (
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
  )

  [[ ${DNF_PACKAGES[@]} =~ "signal-desktop" ]] && (
    sudo dnf config-manager --add-repo https://download.opensuse.org/repositories/network:im:signal/Fedora_37/network:im:signal.repo
    sudo rpm --import https://download.opensuse.org/repositories/network:/im:/signal/Fedora_37/repodata/repomd.xml.key
  )

  ## install additional software ##
  sudo dnf install -y ${DNF_PACKAGES[@]}

  [[ ${#FLATPAK_PACKAGES[@]} -ne 0 ]] && (
    sudo dnf install -y flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak install -y flathub
    sudo flatpak install -y ${FLATPAK_PACKAGES[@]}
  )

  which ansible &> /dev/null && ansible-galaxy collection install community.general vyos.vyos

  # install drawio (won't update automaticly!)
  curl -s https://api.github.com/repos/jgraph/drawio-desktop/releases/latest | grep browser_download_url | grep '\.rpm' | cut -d '"' -f 4 | wget -O /tmp/drawio.rpm -i -
  sudo yum install -y /tmp/drawio.rpm
  sudo rm /tmp/drawio.rpm

  # add password generator script
  sudo wget -q https://raw.githubusercontent.com/felbinger/scripts/master/genpw.sh -O /usr/local/bin/genpw
  sudo chmod +x /usr/local/bin/genpw

  # start jetbrains-toolbox to install idea, pycharm and clion
  curl -s -L -o- $(curl -s "https://data.services.jetbrains.com/products?code=TBA"  | jq -r '.[0].releases | .[0].downloads.linux.link') | tar xzC /tmp
  /tmp/jetbrains-toolbox*/jetbrains-toolbox

  # change ps1
  echo "PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '" | sudo tee -a /{root,home/${USER}}/.bashrc &> /dev/null

  # add your user to some groups for applications
  [[ ${DNF_PACKAGES[@]} =~ "VirtualBox" ]] && sudo usermod -aG vboxusers ${USER}
  sudo usermod -aG dialout ${USER}

  ###############################################
  ##                                           ##
  ##   Configure Desktop Environment Section   ##
  ##                                           ##
  ###############################################

  # use nemo as file manager (instead of gnomes default: nautilus)
  xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search

  # install gnome shell extensions
  extensions=(
    # "https://extensions.gnome.org/extension/2890/tray-icons-reloaded/"
    "https://extensions.gnome.org/extension/3843/just-perfection/"
    "https://extensions.gnome.org/extension/615/appindicator-support/"
  )
  for extension in "${extensions[@]}"; do
    extensionId=$(curl -s $extension | grep -oP 'data-uuid="\K[^"]+')
    versionTag=$(curl -Lfs "https://extensions.gnome.org/extension-query/?search=${extensionId}" | jq '.extensions[0] | .shell_version_map | map(.pk) | max')
    wget -qO /tmp/${extensionId}.zip "https://extensions.gnome.org/download-extension/${extensionId}.shell-extension.zip?version_tag=${versionTag}"
    gnome-extensions install --force /tmp/${extensionId}.zip
    # warning: requires user interaction!
    if ! gnome-extensions list | grep --quiet ${extensionId}; then
        busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions org.gnome.Shell.Extensions InstallRemoteExtension s ${extensionId}
    fi
    gnome-extensions enable ${extensionId}
    rm /tmp/${extensionId}.zip
  done

  # load schemas of installed extensions into gsettings schema database
  find ~/.local/share/gnome-shell/extensions/ -type f -name '*.gschema.xml' \
    -exec sudo cp {} /usr/share/glib-2.0/schemas/ \;
  sudo glib-compile-schemas /usr/share/glib-2.0/schemas/

  # gsettings set org.gnome.shell.extensions.trayIconsReloaded icon-padding-horizontal 0
  # gsettings set org.gnome.shell.extensions.trayIconsReloaded icon-margin-horizontal  0
  # gsettings set org.gnome.shell.extensions.trayIconsReloaded icons-limit 8

  gsettings set org.gnome.shell.extensions.just-perfection activities-button false
  gsettings set org.gnome.shell.extensions.just-perfection world-clock false
  gsettings set org.gnome.shell.extensions.just-perfection weather false
  gsettings set org.gnome.shell.extensions.just-perfection window-menu-take-screenshot-button false
  gsettings set org.gnome.shell.extensions.just-perfection startup-status 0

  gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.desktop.interface enable-hot-corners false
  gsettings set org.gnome.shell.app-switcher current-workspace-only true

  # set background images for screensaver and desktop to static color (#150936)
  path=~/Pictures/background.png
  convert -size 100x100 'xc:#150936' ${path}
  gsettings set org.gnome.desktop.background picture-uri-dark "file://${path}"
  gsettings set org.gnome.desktop.background picture-uri "file://${path}"
  gsettings set org.gnome.desktop.screensaver picture-uri "file://${path}"

  # adjust terminator configuration
  gsettings set org.gnome.desktop.default-applications.terminal exec terminator
  gsettings set org.cinnamon.desktop.default-applications.terminal exec terminator  # required for nemo (right click -> open terminal) to work properly
  gsettings set org.gnome.desktop.default-applications.terminal exec-arg ''
  mkdir -p ~/.config/terminator
  cat <<_EOF >> ~/.config/terminator/config
  [global_config]
  [keybindings]
  [profiles]
    [[default]]
      background_color = "#241f31"
      background_darkness = 0.95
      cursor_color = "#aaaaaa"
      show_titlebar = False
      scrollbar_position = hidden
      scrollback_infinite = True
  [layouts]
    [[default]]
      [[[window0]]]
        type = Window
        parent = ""
      [[[child1]]]
        type = Terminal
        parent = window0
  [plugins]
  _EOF

  gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

  gsettings set org.gnome.desktop.interface clock-show-weekday true
  gsettings set org.gnome.desktop.interface clock-show-seconds true
  gsettings set org.gnome.desktop.datetime automatic-timezone true
  gsettings set org.gnome.desktop.calendar show-weekdate true

  gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
  gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll false

  # add keybinds, see https://askubuntu.com/questions/597395/how-to-set-custom-keyboard-shortcuts-from-terminal
  gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/', '/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/']"

  # disable help keybind
  gsettings set org.gnome.settings-daemon.plugins.media-keys help "[]"

  # CTRL + ALT + T -> CMD: terminator
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Terminal'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'terminator'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Control><Alt>t'

  # CTRL + SHIFT + S -> CMD: flameshot gui
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ name 'Snapshot'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ command 'flameshot gui'
  gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/ binding '<Shift><Control>s'

  # Super + E -> Launchers/Home folder
  gsettings set org.gnome.settings-daemon.plugins.media-keys home "['<Super>e']"

  # configure autostart
  paths=(
    "/usr/share/applications/syncthing-start.desktop"
    "/usr/share/applications/signal-desktop.desktop"
    "/var/lib/flatpak/app/org.ferdium.Ferdium/x86_64/stable/fbca90383214fa94cf7721471902e3ec7b8222dbe7e532b71a9b607c445af2ae/export/share/applications/org.ferdium.Ferdium.desktop"
    "/var/lib/flatpak/app/im.riot.Riot/x86_64/stable/9bd0c958912a8187b019b3a11260da2e6c241b92a6e570fd0efc8b2f53186310/export/share/applications/im.riot.Riot.desktop"
  )
  for path in ${paths[@]}; do
    cp ${path} ~/.config/autostart/
  done
  chmod +x ~/.config/autostart/*.desktop

  # download profile picture for the user
  curl -s -L -o ~/Pictures/profile.png https://avatars.githubusercontent.com/u/26925347

  # start "gnome on xorg" instead of wayland
  sudo sed -i 's/Session=gnome/Session=gnome-xorg/' /var/lib/AccountsService/users/${USER}

  ##############################
  ##                          ##
  ##   Remove Logos Section   ##
  ##                          ##
  ##############################
  # remove fedora logo from gdm
  xhost +si:localuser:gdm
  sudo -u gdm gsettings set org.gnome.login-screen logo ''

  # remove fedora logo from plymouth and regenerate initramfs
  sudo cp /usr/share/plymouth/themes/spinner/watermark.png{,.bak}
  sudo convert -size 128x32 xc:transparent /usr/share/plymouth/themes/spinner/watermark.png
  sudo cp /boot/initramfs-$(uname -r).img{,.bak}
  sudo dracut -f /boot/initramfs-$(uname -r).img


  ### CLEANUP
  rm -r /tmp/repos.d
  rm -r /tmp/jetbrains-toolbox*
  rm -r ~/Public
  rm -r ~/Templates
  sudo dnf remove -y nautilus gnome-text-editor
  ```
</details>

Auch auf meinen Servern war Automatisierung ein wichtiges Thema. Ich setzte lange auf Debian, da es
Stabilität, lange Support-Zyklen und eine große Community bot. Doch auch hier gab es Herausforderungen:
manuelle Konfigurationsänderungen, Paketkonflikte und Updates, die sich nicht immer problemlos durchführen
ließen. Zudem wünschte ich mir eine einfachere Möglichkeit, meine Server-Setups zu dokumentieren und konsistent
zu halten.

Anfangs setzte ich auch hier Post-Install-Skripte ein, um meine Systemstruktur gemäß einem [Admin-Guide](https://adminguide.pages.dev),
den ich mit Freunden erarbeitet hatte, einzurichten. Zur Verwaltung und Konfiguration meiner Server griff ich später auf Ansible zurück,
um Änderungen zentral zu steuern und auszurollen. Allerdings brachte das eine wesentliche Herausforderung mit sich: Ansible berücksichtigt
meist nur den aktuellen Zustand des Systems. Manuelle Änderungen durch Administratoren wurden entweder nicht erkannt oder von späteren
Playbook-Läufen überschrieben, was oft zu unerwarteten Problemen führte. Das System wurde dadurch nicht aus einer fest definierten
Ausgangslage heraus neu aufgebaut, sondern lediglich schrittweise modifiziert - ein grundlegender Unterschied zu NixOS.
Um die Installation der Maschinen zu automatisieren diente eine [Preseed-Konfiguration](https://wiki.debian.org/DebianInstaller/Preseed).

<details>
  <summary>Debian Post-Install Skript gemäß Admin-Guide Struktur</summary>
  ```shell
  #!/bin/bash

  ## CONFIGURATION ###
  ADM_NAME='admin'
  ADM_GID=997
  ADM_HOME='/home/admin'
  ADM_USERS=('user')

  declare -A STACKS=(\
    ["main"]="172.30.100.0/24"
    ["comms"]="172.30.101.0/24"
    ["storage"]="172.30.102.0/24"
  )

  declare -A HELPER=(\
    ["proxy"]="172.30.0.0/24" \
    ["database"]="172.30.1.0/24" \
    ["monitoring"]="172.30.2.0/24"
  )
  ### END of CONFIGURATION ###

  function create_compose() {
    cp resources/docker-compose.template.yml ${1}
    # stack network
    echo -e "    external:" >>${compose}
    echo -e "      name: ${name}" >>${compose}

    # define helper networks
    for helper_name in ${!HELPER[@]}; do
      echo -e "  ${helper_name}:" >>${compose}
      echo -e "    external:" >>${compose}
      echo -e "      name: ${helper_name}" >>${compose}
    done
  }

  # require root privileges
  if [[ $(/usr/bin/id -u) != "0" ]]; then
    echo "Please run the script as root!"
    exit 1
  fi

  if [[ ${RERUN} == 1 ]]; then
    echo "You already ran the script, if you really want to run the script again set 'RERUN=0'. (This might break your system!)"
    exit 1
  fi

  # add rerun=1 variable to prevent postinstall to be executed multiple times
  sed -i '2 i\RERUN=1' ${0}

  echo ">>> Installing Software"
  apt-get update
  apt-get install sudo curl wget borgbackup

  # install docker if not already installed
  if [[ -z $(which docker) ]]; then
    curl https://get.docker.com | bash
  fi

  # install docker-compose if not already installed
  if [[ -z $(which docker-compose) ]]; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
  fi

  # remove trailing slash from ADM_HOME
  [[ "${ADM_HOME}" == */ ]] && ADM_HOME="${ADM_HOME::-1}"

  # create admin group, add members to group and set permissions
  echo ">>> Creating Admin Setup"
  /usr/sbin/groupadd -g ${ADM_GID} ${ADM_NAME}
  mkdir ${ADM_HOME}
  chown -R root:${ADM_NAME} ${ADM_HOME}
  chmod -R 775 ${ADM_HOME}
  for user in ${ADM_USERS[@]}; do
    # check if user exists
    if [ ! $(sed -n "/^${user}/p" /etc/passwd) ]; then
      /usr/sbin/useradd --create-home --shell=/bin/bash ${user}
    fi
    /usr/sbin/usermod --append --groups=sudo,${ADM_NAME} ${user}

    # add aliases
    echo -e '\nalias dc="sudo docker-compose "' | tee -a /home/${user}/.bashrc > /dev/null
    echo -e 'alias ctop="sudo ctop"\n' | tee -a /home/${user}/.bashrc > /dev/null

    # check if exist
    [ ! -h "/home/{user}/admin" ] && ln -s ${ADM_HOME} /home/${user}/admin
  done

  echo ">>> Creating Docker Stacks"
  # create helper networks
  for name in ${!HELPER[@]}; do
    docker network inspect ${name} >/dev/null 2>&1 || docker network create --subnet ${HELPER[${name}]} ${name}
  done

  # create stack logic
  mkdir -p ${ADM_HOME}/{services,images,tools,docs}/
  for name in ${!STACKS[@]}; do
    mkdir -p "${ADM_HOME}/{services,images}/${name}/" "/srv/${name}/"

    # create stack network
    docker network inspect ${name} >/dev/null 2>&1 || docker network create --subnet ${STACKS[${name}]} ${name}

    # create docker-compose.yml
    [ ! -f "${ADM_HOME}/services/${name}/docker-compose.yml" ] && create_compose "${ADM_HOME}/services/${name}/docker-compose.yml"
  done

  # adjust permissions
  chown -R root:admin ${ADM_HOME}
  find ${ADM_HOME} -type d -exec chmod 0775 {} \;
  find ${ADM_HOME} -type f -exec chmod 0664 {} \;
  find ${ADM_HOME}/tools/ -type f -exec chmod 0775 {} \;
  ```
</details>

<details>
  <summary>Struktur meines Ansible Repositories</summary>
  ```
  ansible
  ├── group_vars
  ├── host_vars
  │   ├── example.felbinger.eu
  │   ├── monitoring.felbinger.eu
  │   ├── netbox.felbinger.eu
  │   ├── preseed.felbinger.eu
  │   └── vyos.felbinger.eu
  ├── roles
  │   ├── ansible-role-felbinger_container
  │   │   ├── defaults
  │   │   └── tasks
  │   ├── ansible-role-felbinger_logging
  │   │   ├── handlers
  │   │   └── tasks
  │   ├── ansible-role-felbinger_monitoring
  │   │   ├── defaults
  │   │   ├── files
  │   │   ├── tasks
  │   │   └── templates
  │   ├── ansible-role-felbinger_netbox_init
  │   │   └── tasks
  │   └── ansible-role-felbinger_nginx
  │       ├── handlers
  │       ├── tasks
  │       └── templates
  ├── tasks
  └── templates
  ```
</details>

<details>
  <summary>Debian Preseed Konfiguration</summary>
  ```shell
  #_preseed_V1
  #### Contents of the preconfiguration file (for bullseye)
  ### Localization
  # Preseeding only locale sets language, country and locale.
  d-i debian-installer/locale string en_US

  # The values can also be preseeded individually for greater flexibility.
  #d-i debian-installer/language string en
  #d-i debian-installer/country string US
  #d-i debian-installer/locale string en_US.UTF-8
  # Optionally specify additional locales to be generated.
  #d-i localechooser/supported-locales multiselect en_US.UTF-8, nl_NL.UTF-8

  # Keyboard selection.
  d-i keyboard-configuration/xkb-keymap select de
  # d-i keyboard-configuration/toggle select No toggling

  ### Network configuration
  # Disable network configuration entirely. This is useful for cdrom
  # installations on non-networked devices where the network questions,
  # warning and long timeouts are a nuisance.
  #d-i netcfg/enable boolean false

  # netcfg will choose an interface that has link if possible. This makes it
  # skip displaying a list if there is more than one interface.
  d-i netcfg/choose_interface select auto

  # To pick a particular interface instead:
  #d-i netcfg/choose_interface select eth1

  # To set a different link detection timeout (default is 3 seconds).
  # Values are interpreted as seconds.
  #d-i netcfg/link_wait_timeout string 10

  # If you have a slow dhcp server and the installer times out waiting for
  # it, this might be useful.
  #d-i netcfg/dhcp_timeout string 60
  #d-i netcfg/dhcpv6_timeout string 60

  # If you prefer to configure the network manually, uncomment this line and
  # the static network configuration below.
  #d-i netcfg/disable_autoconfig boolean true

  # If you want the preconfiguration file to work on systems both with and
  # without a dhcp server, uncomment these lines and the static network
  # configuration below.
  #d-i netcfg/dhcp_failed note
  #d-i netcfg/dhcp_options select Configure network manually

  # Static network configuration.
  #
  # IPv4 example
  #d-i netcfg/get_ipaddress string 192.168.1.42
  #d-i netcfg/get_netmask string 255.255.255.0
  #d-i netcfg/get_gateway string 192.168.1.1
  #d-i netcfg/get_nameservers string 192.168.1.1
  #d-i netcfg/confirm_static boolean true
  #
  # IPv6 example
  #d-i netcfg/get_ipaddress string fc00::2
  #d-i netcfg/get_netmask string ffff:ffff:ffff:ffff::
  #d-i netcfg/get_gateway string fc00::1
  #d-i netcfg/get_nameservers string fc00::1
  #d-i netcfg/confirm_static boolean true

  # Any hostname and domain names assigned from dhcp take precedence over
  # values set here. However, setting the values still prevents the questions
  # from being shown, even if values come from dhcp.
  #d-i netcfg/get_hostname string unassigned-hostname
  #d-i netcfg/get_domain string unassigned-domain

  # If you want to force a hostname, regardless of what either the DHCP
  # server returns or what the reverse DNS entry for the IP is, uncomment
  # and adjust the following line.
  #d-i netcfg/hostname string somehost

  # Disable that annoying WEP key dialog.
  d-i netcfg/wireless_wep string
  # The wacky dhcp hostname that some ISPs use as a password of sorts.
  #d-i netcfg/dhcp_hostname string radish

  # If non-free firmware is needed for the network or other hardware, you can
  # configure the installer to always try to load it, without prompting. Or
  # change to false to disable asking.
  #d-i hw-detect/load_firmware boolean true

  ### Network console
  # Use the following settings if you wish to make use of the network-console
  # component for remote installation over SSH. This only makes sense if you
  # intend to perform the remainder of the installation manually.
  #d-i anna/choose_modules string network-console
  #d-i network-console/authorized_keys_url string http://10.0.0.1/openssh-key
  #d-i network-console/password password r00tme
  #d-i network-console/password-again password r00tme

  ### Mirror settings
  # If you select ftp, the mirror/country string does not need to be set.
  #d-i mirror/protocol string ftp
  #d-i mirror/country string manual
  #d-i mirror/http/hostname string http.us.debian.org
  #d-i mirror/http/directory string /debian
  #d-i mirror/http/proxy string

  # Suite to install.
  #d-i mirror/suite string testing
  # Suite to use for loading installer components (optional).
  #d-i mirror/udeb/suite string testing

  ### Account setup
  # Skip creation of a root account (normal user account will be able to
  # use sudo).
  d-i passwd/root-login boolean false
  # Alternatively, to skip creation of a normal user account.
  #d-i passwd/make-user boolean false

  # Root password, either in clear text
  #d-i passwd/root-password password r00tme
  #d-i passwd/root-password-again password r00tme
  # or encrypted using a crypt(3)  hash.
  #d-i passwd/root-password-crypted password $6$iX9o7PncqLMMb/ds$R1lMbxbOrctLbfe.eFk2nvduBbvL8Zzb/t/PPfUtzgb74n3Cehe9CZ42G5xx9U09DN27Z.CxwByJG60ylKfv50

  # To create a normal user account.
  d-i passwd/user-fullname string Ansible
  d-i passwd/username string ansible
  # Normal user's password, either in clear text
  #d-i passwd/user-password password insecure
  #d-i passwd/user-password-again password insecure
  # or encrypted using a crypt(3) hash.
  d-i passwd/user-password-crypted password $6$iX9o7PncqLMMb/ds$R1lMbxbOrctLbfe.eFk2nvduBbvL8Zzb/t/PPfUtzgb74n3Cehe9CZ42G5xx9U09DN27Z.CxwByJG60ylKfv50
  # Create the first user with the specified UID instead of the default.
  #d-i passwd/user-uid string 1010

  # The user account will be added to some standard initial groups. To
  # override that, use this.
  #d-i passwd/user-default-groups string sudo

  ### Clock and time zone setup
  # Controls whether or not the hardware clock is set to UTC.
  d-i clock-setup/utc boolean true

  # You may set this to any valid setting for $TZ; see the contents of
  # /usr/share/zoneinfo/ for valid values.
  d-i time/zone string Europe/Berlin

  # Controls whether to use NTP to set the clock during the install
  d-i clock-setup/ntp boolean true
  # NTP server to use. The default is almost always fine here.
  #d-i clock-setup/ntp-server string ntp.example.com

  ### Partitioning
  ## Partitioning example
  # If the system has free space you can choose to only partition that space.
  # This is only honoured if partman-auto/method (below) is not set.
  #d-i partman-auto/init_automatically_partition select biggest_free

  # Alternatively, you may specify a disk to partition. If the system has only
  # one disk the installer will default to using that, but otherwise the device
  # name must be given in traditional, non-devfs format (so e.g. /dev/sda
  # and not e.g. /dev/discs/disc0/disc).
  # For example, to use the first SCSI/SATA hard disk:
  #d-i partman-auto/disk string /dev/sda
  # In addition, you'll need to specify the method to use.
  # The presently available methods are:
  # - regular: use the usual partition types for your architecture
  # - lvm:     use LVM to partition the disk
  # - crypto:  use LVM within an encrypted partition
  d-i partman-auto/method string lvm

  d-i partman-auto-lvm/new_vg_name string debian-vg

  # You can define the amount of space that will be used for the LVM volume
  # group. It can either be a size with its unit (eg. 20 GB), a percentage of
  # free space or the 'max' keyword.
  d-i partman-auto-lvm/guided_size string max

  # If one of the disks that are going to be automatically partitioned
  # contains an old LVM configuration, the user will normally receive a
  # warning. This can be preseeded away...
  d-i partman-lvm/device_remove_lvm boolean true
  # The same applies to pre-existing software RAID array:
  d-i partman-md/device_remove_md boolean true
  # And the same goes for the confirmation to write the lvm partitions.
  d-i partman-lvm/confirm boolean true
  d-i partman-lvm/confirm_nooverwrite boolean true

  # You can choose one of the three predefined partitioning recipes:
  # - atomic: all files in one partition
  # - home:   separate /home partition
  # - multi:  separate /home, /var, and /tmp partitions
  d-i partman-auto/choose_recipe select atomic

  # Or provide a recipe of your own...
  # If you have a way to get a recipe file into the d-i environment, you can
  # just point at it.
  #d-i partman-auto/expert_recipe_file string /hd-media/recipe

  # If not, you can put an entire recipe into the preconfiguration file in one
  # (logical) line. This example creates a small /boot partition, suitable
  # swap, and uses the rest of the space for the root partition:
  #d-i partman-auto/expert_recipe string                         \
  #      boot-root ::                                            \
  #              40 50 100 ext3                                  \
  #                      $primary{ } $bootable{ }                \
  #                      method{ format } format{ }              \
  #                      use_filesystem{ } filesystem{ ext3 }    \
  #                      mountpoint{ /boot }                     \
  #              .                                               \
  #              500 10000 1000000000 ext3                       \
  #                      method{ format } format{ }              \
  #                      use_filesystem{ } filesystem{ ext3 }    \
  #                      mountpoint{ / }                         \
  #              .                                               \
  #              64 512 300% linux-swap                          \
  #                      method{ swap } format{ }                \
  #              .

  # The full recipe format is documented in the file partman-auto-recipe.txt
  # included in the 'debian-installer' package or available from D-I source
  # repository. This also documents how to specify settings such as file
  # system labels, volume group names and which physical devices to include
  # in a volume group.

  ## Partitioning for EFI
  # If your system needs an EFI partition you could add something like
  # this to the recipe above, as the first element in the recipe:
  #               538 538 1075 free                              \
  #                      $iflabel{ gpt }                         \
  #                      $reusemethod{ }                         \
  #                      method{ efi }                           \
  #                      format{ }                               \
  #               .                                              \
  #
  # The fragment above is for the amd64 architecture; the details may be
  # different on other architectures. The 'partman-auto' package in the
  # D-I source repository may have an example you can follow.

  # This makes partman automatically partition without confirmation, provided
  # that you told it what to do using one of the methods above.
  d-i partman-partitioning/confirm_write_new_label boolean true
  d-i partman/choose_partition select finish
  d-i partman/confirm boolean true
  d-i partman/confirm_nooverwrite boolean true

  # Force UEFI booting ('BIOS compatibility' will be lost). Default: false.
  #d-i partman-efi/non_efi_system boolean true
  # Ensure the partition table is GPT - this is required for EFI
  #d-i partman-partitioning/choose_label string gpt
  #d-i partman-partitioning/default_label string gpt

  # When disk encryption is enabled, skip wiping the partitions beforehand.
  #d-i partman-auto-crypto/erase_disks boolean false

  ## Partitioning using RAID
  # The method should be set to "raid".
  #d-i partman-auto/method string raid
  # Specify the disks to be partitioned. They will all get the same layout,
  # so this will only work if the disks are the same size.
  #d-i partman-auto/disk string /dev/sda /dev/sdb

  # Next you need to specify the physical partitions that will be used.
  #d-i partman-auto/expert_recipe string \
  #      multiraid ::                                         \
  #              1000 5000 4000 raid                          \
  #                      $primary{ } method{ raid }           \
  #              .                                            \
  #              64 512 300% raid                             \
  #                      method{ raid }                       \
  #              .                                            \
  #              500 10000 1000000000 raid                    \
  #                      method{ raid }                       \
  #              .

  # Last you need to specify how the previously defined partitions will be
  # used in the RAID setup. Remember to use the correct partition numbers
  # for logical partitions. RAID levels 0, 1, 5, 6 and 10 are supported;
  # devices are separated using "#".
  # Parameters are:
  # <raidtype> <devcount> <sparecount> <fstype> <mountpoint> \
  #          <devices> <sparedevices>

  #d-i partman-auto-raid/recipe string \
  #    1 2 0 ext3 /                    \
  #          /dev/sda1#/dev/sdb1       \
  #    .                               \
  #    1 2 0 swap -                    \
  #          /dev/sda5#/dev/sdb5       \
  #    .                               \
  #    0 2 0 ext3 /home                \
  #          /dev/sda6#/dev/sdb6       \
  #    .

  # For additional information see the file partman-auto-raid-recipe.txt
  # included in the 'debian-installer' package or available from D-I source
  # repository.

  # This makes partman automatically partition without confirmation.
  d-i partman-md/confirm boolean true
  d-i partman-partitioning/confirm_write_new_label boolean true
  d-i partman/choose_partition select finish
  d-i partman/confirm boolean true
  d-i partman/confirm_nooverwrite boolean true

  ## Controlling how partitions are mounted
  # The default is to mount by UUID, but you can also choose "traditional" to
  # use traditional device names, or "label" to try filesystem labels before
  # falling back to UUIDs.
  #d-i partman/mount_style select uuid

  ### Base system installation
  # Configure APT to not install recommended packages by default. Use of this
  # option can result in an incomplete system and should only be used by very
  # experienced users.
  #d-i base-installer/install-recommends boolean false

  # The kernel image (meta) package to be installed; "none" can be used if no
  # kernel is to be installed.
  #d-i base-installer/kernel/image string linux-image-686

  ### Apt setup
  # You can choose to install non-free and contrib software.
  #d-i apt-setup/non-free boolean true
  #d-i apt-setup/contrib boolean true
  # Uncomment this if you don't want to use a network mirror.
  #d-i apt-setup/use_mirror boolean false
  # Select which update services to use; define the mirrors to be used.
  # Values shown below are the normal defaults.
  #d-i apt-setup/services-select multiselect security, updates
  #d-i apt-setup/security_host string security.debian.org

  # Additional repositories, local[0-9] available
  #d-i apt-setup/local0/repository string \
  #       http://local.server/debian stable main
  # https://docs.hetzner.com/robot/dedicated-server/operating-systems/hetzner-aptitude-mirror/
  d-i apt-setup/local0/repository string http://deb.debian.org/debian/ bullseye main contrib non-free
  d-i apt-setup/local1/repository string http://deb.debian.org/debian/ bullseye-updates main contrib non-free
  #d-i apt-setup/local2/repository string http://security.debian.org/debian-security bullseye-security main contrib non-free  # exists by default
  #d-i apt-setup/local0/comment string local server
  # Enable deb-src lines
  d-i apt-setup/local0/source boolean true
  d-i apt-setup/local1/source boolean true
  # URL to the public key of the local repository; you must provide a key or
  # apt will complain about the unauthenticated repository and so the
  # sources.list line will be left commented out.
  #d-i apt-setup/local0/key string http://local.server/key
  # If the provided key file ends in ".asc" the key file needs to be an
  # ASCII-armoured PGP key, if it ends in ".gpg" it needs to use the
  # "GPG key public keyring" format, the "keybox database" format is
  # currently not supported.

  # By default the installer requires that repositories be authenticated
  # using a known gpg key. This setting can be used to disable that
  # authentication. Warning: Insecure, not recommended.
  #d-i debian-installer/allow_unauthenticated boolean true

  # Uncomment this to add multiarch configuration for i386
  #d-i apt-setup/multiarch string i386


  ### Package selection
  tasksel tasksel/first multiselect standard

  # Individual additional packages to install
  #d-i pkgsel/include string openssh-server build-essential
  d-i pkgsel/include string wget curl sudo sed python3 openssh-server build-essential
  # Whether to upgrade packages after debootstrap.
  # Allowed values: none, safe-upgrade, full-upgrade
  #d-i pkgsel/upgrade select none

  # Some versions of the installer can report back on what software you have
  # installed, and what software you use. The default is not to report back,
  # but sending reports helps the project determine what software is most
  # popular and should be included on the first CD/DVD.
  #popularity-contest popularity-contest/participate boolean false

  ### Boot loader installation
  # Grub is the boot loader (for x86).

  # This is fairly safe to set, it makes grub install automatically to the UEFI
  # partition/boot record if no other operating system is detected on the machine.
  d-i grub-installer/only_debian boolean true

  # This one makes grub-installer install to the UEFI partition/boot record, if
  # it also finds some other OS, which is less safe as it might not be able to
  # boot that other OS.
  #d-i grub-installer/with_other_os boolean true

  # Due notably to potential USB sticks, the location of the primary drive can
  # not be determined safely in general, so this needs to be specified:
  #d-i grub-installer/bootdev  string /dev/sda
  # To install to the primary device (assuming it is not a USB stick):
  d-i grub-installer/bootdev  string default

  # Alternatively, if you want to install to a location other than the UEFI
  # parition/boot record, uncomment and edit these lines:
  #d-i grub-installer/only_debian boolean false
  #d-i grub-installer/with_other_os boolean false
  #d-i grub-installer/bootdev  string (hd0,1)
  # To install grub to multiple disks:
  #d-i grub-installer/bootdev  string (hd0,1) (hd1,1) (hd2,1)

  # Optional password for grub, either in clear text
  #d-i grub-installer/password password r00tme
  #d-i grub-installer/password-again password r00tme
  # or encrypted using an MD5 hash, see grub-md5-crypt(8).
  #d-i grub-installer/password-crypted password [MD5 hash]

  # Use the following option to add additional boot parameters for the
  # installed system (if supported by the bootloader installer).
  # Note: options passed to the installer will be added automatically.
  #d-i debian-installer/add-kernel-opts string nousb

  ### Finishing up the installation
  # During installations from serial console, the regular virtual consoles
  # (VT1-VT6) are normally disabled in /etc/inittab. Uncomment the next
  # line to prevent this.
  #d-i finish-install/keep-consoles boolean true

  # Avoid that last message about the install being complete.
  d-i finish-install/reboot_in_progress note

  # This will prevent the installer from ejecting the CD during the reboot,
  # which is useful in some situations.
  #d-i cdrom-detect/eject boolean false

  # This is how to make the installer shutdown when finished, but not
  # reboot into the installed system.
  #d-i debian-installer/exit/halt boolean true
  # This will power off the machine instead of just halting it.
  #d-i debian-installer/exit/poweroff boolean true

  ### Preseeding other packages
  # Depending on what software you choose to install, or if things go wrong
  # during the installation process, it's possible that other questions may
  # be asked. You can preseed those too, of course. To get a list of every
  # possible question that could be asked during an install, do an
  # installation, and then run these commands:
  #   debconf-get-selections --installer > file
  #   debconf-get-selections >> file


  #### Advanced options
  ### Running custom commands during the installation
  # d-i preseeding is inherently not secure. Nothing in the installer checks
  # for attempts at buffer overflows or other exploits of the values of a
  # preconfiguration file like this one. Only use preconfiguration files from
  # trusted locations! To drive that home, and because it's generally useful,
  # here's a way to run any shell command you'd like inside the installer,
  # automatically.

  # This first command is run as early as possible, just after
  # preseeding is read.
  #d-i preseed/early_command string anna-install some-udeb
  # This command is run immediately before the partitioner starts. It may be
  # useful to apply dynamic partitioner preseeding that depends on the state
  # of the disks (which may not be visible when preseed/early_command runs).
  #d-i partman/early_command \
  #       string debconf-set partman-auto/disk "$(list-devices disk | head -n1)"
  # This command is run just before the install finishes, but when there is
  # still a usable /target directory. You can chroot to /target and use it
  # directly, or use the apt-install and in-target commands to easily install
  # packages and run commands in the target system.
  #d-i preseed/late_command string apt-install zsh; in-target chsh -s /bin/zsh

  d-i preseed/late_command string in-target sed -i "/^deb cdrom:/s/^/# /" /etc/apt/sources.list; \
                                  in-target sed -i -e "/#PermitRootLogin.* /{ s|#|| ; s|prohibit-password|no| }" /etc/ssh/sshd_config; \
                                  in-target sed -i -e "/#PasswordAuthentication.* /{ s|#|| ; s|yes|no| }" /etc/ssh/sshd_config; \
                                  in-target mkdir -p /home/ansible/.ssh/; \
                                  in-target chown -R ansible:ansible /home/ansible/.ssh; \
                                  in-target sh -c 'echo "ssh-rsa <-cut-> ansible@WS1" >> /home/ansible/.ssh/authorized_keys';
  ```
</details>

Der Wunsch nach einer besseren Lösung führte mich schließlich zu NixOS. Bereits 2020 erzählte mir ein
Bekannter von den Vorteilen. Zunächst war ich skeptisch, doch als immer mehr Freunde und Kollegen von
ihren positiven Erfahrungen berichteten, begann ich mich näher mit dem Konzept auseinanderzusetzen.

Der Nix-Paketmanager klang vielversprechend, aber auch ungewohnt. Mein erstes Experiment war
eine Testinstallation in einer VM - und schon nach kurzer Zeit erkannte ich das Potenzial. Die
anfängliche Lernkurve war zwar steil, aber ich merkte schnell, dass sich der Aufwand lohnte.

Nachdem die ersten Tests vielversprechend verliefen, installierte ich NixOS auf meinem Notebook.
Anschließend begann ich, einzelne Dienste wie einen Monitoring-Server und einen NetBox-Server mit
NixOS umzusetzen. Da dies reibungslos funktionierte, entschied ich mich, nach und nach immer mehr Systeme
umzustellen.

Im Rahmen einer wissenschaftlichen Arbeit analysierte ich zudem die Sicherheit von NixOS. In diesem Rahmen kann ich
besonders die [Doktorarbeit von E. Dolstra zu Nix](https://edolstra.github.io/pubs/phd-thesis.pdf), sowie
das [Paper zur Finalisierung von NixOS](https://edolstra.github.io/pubs/nixos-jfp-final.pdf) empfehlen.
Diese Arbeiten geben tiefe Einblicke in die Architektur von Nix und NixOS.

Der Umstieg auf NixOS war für mich ein logischer Schritt, um mein System zuverlässiger, flexibler und
effizienter zu verwalten. Obwohl die Lernkurve anfangs sehr steil war, hat sich der Aufwand mehr als
gelohnt. Heute genieße ich die Vorteile eines vollständig deklarativen und reproduzierbaren Systems -
und kann mir kaum vorstellen, zu einer klassischen Linux-Distribution zurückzukehren.
