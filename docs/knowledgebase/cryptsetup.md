# Cryptsetup
## Decrypt using ssh
If you want to encrypt your system using cryptsetup to make it more difficult
for curious administrators or attackers who were able to take over a hypervisor
to access your data (at least if the virtual machine was previously offline),
it is a good idea to set up the dropbear ssh server. This allows you to enter
a password for decryption via ssh, instead of using the Proxmox vnc console,
where copy/paste cannot be used.

```sh
apt install dropbear-initramfs
echo "ssh-ed25519 ..." | tee -a /etc/dropbear-initramfs/authorized_keys

# adjust dropbear config
sed -i 's|#\(DROPBEAR_OPTIONS\).*|\1="-I 60 -R -F -E -j -k -p 2222 -s -c /bin/cryptroot-unlock"|' /etc/dropbear-initramfs/config

# enable networking in initramfs
# format: ip=<client-ip>:<server-ip>:<gw-ip>:<netmask>:<hostname>:<device>:<autoconf>:<dns-server-0-ip>:<dns-server-1-ip>:<ntp0-ip>
# use dhcp
IP=:::::ens18:dhcp
# or static ip
IP=10.0.0.2::10.0.0.1:255.255.255.0

update-initramfs -u
```

## Nuke password
Additionally you may want to create a nuke password for cryptsetup. If an
attacker tries to log in with this password, all key information is deleted
from the luks-header, so that it is impossible to decrypt it again.

```sh
apt install cryptsetup-nuke-password
echo NukePassword | /usr/lib/cryptsetup-nuke-password/crypt --generate
update-initramfs -u
```

Afterwards, the system can continue to be used as normal. If the nuke password
is entered, the key information in the luks-header is irrevocably deleted.

For this reason, you should create a backup of the luks-headers. This can be
restored via a live boot system in the event of a deletion. Keep in mind that
you have to create the backup of the luks-header every time you change one of
the decryption passphrases.
```sh
# backup header after initial setup and store it in a safe place.
cryptsetup luksHeaderBackup /dev/sda5 --header-backup-file /root/luksheader.bck

# restore luks header using live system
cryptsetup luksHeaderRestore /dev/sda5 --header-backup-file <file>
```

