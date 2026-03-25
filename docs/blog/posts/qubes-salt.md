---
date:
  created: 2026-03-24
  updated: 2026-03-25
authors:
- nicof2000
categories:
- QubesOS
- SaltStack
readtime: 5
draft: true
---
# Manage QubesOS declaratively using SaltStack

<!-- based on https://dataswamp.org/~solene/2023-06-02-reproducible-config-mgmt-qubes-os.html -->

## Terminator
```yaml
install_terminator:
  pkg.installed:
    - pkgs:
        - terminator

/home/user/.config/terminator/config:
  file.managed
    # fix broken font
    - contents: |
        [global_config]
        [keybindings]
        [profiles]
          [[default]]
            font = Monospace 12
            use_system_font = False
        [layouts]
    - user: user
    - group: user
    - mode: 0644
    - makedirs: true
```

## Git
```yaml
{% for u in ['user', 'root'] %}
configure_git_for_{{ u }}:
  file.managed:
    - name: {% if u == 'root' %}/root{% else %}/home/{{ u }}{% endif %}/.gitconfig
    - source: salt://files/gitconfig
    - user: {{ u }}
    - group: {{ u }}
    - mode: 0644
{% endfor %}
```
with files/gitconfig:
```ini
[user]
  name = First Last
  email = first.last@example.com
```

## Visual Studio Code
```yaml
vscode.repo:
  pkgrepo.managed:
    - humanname: Visual Studio Code
    - baseurl: https://packages.microsoft.com/yumrepos/vscode
    - gpgkey: https://packages.microsoft.com/keys/microsoft.asc
    - gpgcheck: 1

install_vscode:
  pkg.installed:
    - pkgs:
        - code
```

## Codium
Thanks to solene, see: <https://forum.qubes-os.org/t/handle-flatpak-from-salt/30157>
```yaml
install_flatpak:
  pkg.installed:
    - pkgs:
        - flatpak

flatpak_setup:
  cmd.script:
    - source: salt://files/flatpak-setup.sh
    - template: jinja
    - context:
        flatpak_packages: com.vscodium.codium

/etc/qubes/post-install.d/05-flatpak-update.sh:
  file.managed:
    - user: root
    - group: wheel
    - mode: 0555
    - contents: |
        #!/bin/sh
        if [ $(qubesdb-read /type) = "TemplateVM" ]; then
          flatpak upgrade -y --noninteractive
        fi
```
with `files/flatpak-setup.sh`:
```sh
#!/bin/sh
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# list programs that should be installed
flatpak install -y --noninteractive flathub {{ flatpak_packages }}

# make flatpak programs available in menus
find /var/lib/flatpak/exports/share/applications/ -type l -name "*.desktop" -exec ln -s {} /usr/share/applications/ \;

# delete dead links, in case a flatpak program was deleted
find /usr/share/applications/ -xtype l -delete

/etc/qubes/post-install.d/10-qubes-core-agent-appmenus.sh
```
