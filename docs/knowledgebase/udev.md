# udev
You can hide partitions (e. g. the Windows Boot Partition) from your file manager using a simple udev rule:
```shell
# get uuid of partition you want to hide
part_dev=/dev/sdb1
part_id=$(sudo udevadm info --query=all -n ${part_dev} | grep ID_PART_ENTRY_UUID | cut -d= -f2)

# create udev rule
echo 'ENV{ID_PART_ENTRY_UUID}=="'${part_id}'", ENV{UDISKS_IGNORE}="1"' | sudo tee -a /etc/udev/rules.d/99-unplug-boot.rules

# apply the created rule
sudo udevadm control --reload-rules && sudo udevadm trigger
```
