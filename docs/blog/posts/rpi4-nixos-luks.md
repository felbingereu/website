---
date:
  created: 2026-06-13
authors:
- nicof2000
categories:
- NixOS
readtime: 3
---

# NixOS on Raspberry Pi 4 with Encrypted Filesystem (2026)

First I downloaded the latest `nixos-image-sd-card-*-aarch64-linux.img` from hydra
(see <https://hydra.nixos.org/job/nixos/release-26.05/nixos.sd_image.aarch64-linux>)
and flashed it onto an usb stick.

Next I booted the Raspberry Pi from the USB stick, waited for the system to finish starting, then reinserted the microSD card.

<!-- more -->

!!! info
    The Raspberry Pi may need a firmware upgrade to support booting from USB
    (see <https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_4#USB_boot>).
    ```sh
    nix-shell -p raspberrypi-eeprom --run 'rpi-eeprom-update -d -a'
    ```

The guide at <https://www.thenegation.com/posts/nixos-rpi4-luks/> was followed for the most part,
though it's slightly outdated. Since nixpkgs 26.05, the Raspberry Pi vendor kernel was removed
from the binary cache and will soon be removed from nixpkgs entirely. Attempting to use it causes
long installation times because the kernel must be built locally. Most users will be fine using
the standard aarch64-linux kernel - more details follow after the installation process.

```sh
wipefs -a /dev/mmcblk0

parted /dev/mmcblk0 -- mklabel gpt
parted /dev/mmcblk0 -- mkpart ESP fat32 1MiB 4096MiB
parted /dev/mmcblk0 -- set 1 boot on
parted /dev/mmcblk0 -- mkpart primary 4096MiB 100%

cryptsetup luksFormat /dev/mmcblk0p2
cryptsetup luksOpen /dev/mmcblk0p2 cryptroot

pvcreate /dev/mapper/cryptroot
vgcreate vg0 /dev/mapper/cryptroot
lvcreate -l '100%FREE' -n root vg0

mkfs.fat /dev/mmcblk0p1
mkfs.ext4 -L root /dev/vg0/root

mount /dev/vg0/root /mnt
mkdir /mnt/boot
mount /dev/mmcblk0p1 /mnt/boot

mkdir /firmware
mount /dev/sda1 /firmware
cp /firmware/* /mnt/boot
umount /firmware

sudo nixos-generate-config --root /mnt
cat <<_EOF > /mnt/etc/nixos/configuration.nix
{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };

    initrd.luks.devices.luksroot = {
      device = "/dev/disk/by-uuid/$(sudo blkid /dev/mmcblk0p2 | sed -E 's/.*\sUUID="([a-f0-9-]+)".*/\1/')";
      preLVM = true;
      allowDiscards = true;
    };
  };

  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
_EOF

nixos-install
```

After reboot, the initrd prompted to unlock the drive. My USB keyboard failed to respond (probally the driver hasn't been loaded),
so I used UART (GPIO 14 for TXD and GPIO 15 for RXD, see <https://pinout.xyz/pinout/uart>) to unlock the drive and configure the network.
[Remote unlocking](https://wiki.nixos.org/wiki/Remote_disk_unlocking) was then planned to be configured anyway, so it didn't matter for me.

For Raspberry PI related features (e.g. i2c, gpio, ...) take a look at <https://github.com/NixOS/nixos-hardware/blob/master/raspberry-pi/4/>.

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      nixpkgs,
      nixos-hardware,
      ...
    }@inputs:
    let
      inherit (inputs.nixpkgs) lib;
      defaultSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      eachDefaultSystem = lib.genAttrs defaultSystems;
      system = "aarch64-linux";
    in
    {
      nixosConfigurations.rpi = nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = import nixpkgs { inherit system; };
        modules = [
          ./configuration.nix
          nixos-hardware.nixosModules.raspberry-pi-4
        ];
      };
    };
}
```
