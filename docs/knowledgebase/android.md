# Android
## Samsung Galaxy A3
- [LineageOS: Samsung Galaxy A3 (2017) - SM-A320FL - a3y17lte](https://gist.github.com/felbinger/864f48accc3d634c098f9d9126188415)

## Asus Nexus 7
- Original firmware: [developers.google.com/android/ota](https://developers.google.com/android/ota#razor)
- LinageOS: [wiki.lineageos.org/devices/flox/install](https://wiki.lineageos.org/devices/flox/install).
- Nethunter: [pentestit.de/kali-nethunter-2020-teil-1-installation-auf-nexus-7/](https://pentestit.de/kali-nethunter-2020-teil-1-installation-auf-nexus-7/)
- Flash TWRP
  ```shell
  # adb devices
  List of devices attached
  0909da6e	recovery

  # adb reboot bootloader

  # sudo fastboot devices
  0909da6e	fastboot

  # sudo fastboot oem unlock
  (bootloader) Unlocking bootloader...
  (bootloader) erasing userdata...
  (bootloader) erasing userdata done
  (bootloader) erasing cache...
  (bootloader) erasing cache done
  (bootloader) Unlocking bootloader done!
  OKAY [ 24.086s]
  Finished. Total time: 24.086s

  # sudo fastboot flash recovery twrp-3.5.2_9-0-flo.img
  Sending 'recovery' (10060 KB)                      OKAY [  0.325s]
  Writing 'recovery'                                 OKAY [  0.386s]
  Finished. Total time: 0.723s

  # sudo fastboot reboot recovery
  ```

## Google Pixel 4a
- Original firmware: [developers.google.com/android/ota](https://developers.google.com/android/ota#sunfish)
- LineageOS: [wiki.lineageos.org/devices/sunfish/](https://wiki.lineageos.org/devices/sunfish/)
- GrapheneOS: [grapheneos.org/releases](https://grapheneos.org/releases#sunfish-stable)
