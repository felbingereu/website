# Raspberry PI
- [pinout.xyz](https://pinout.xyz/)
- [RaspberryPI OS](https://www.raspberrypi.com/software/operating-systems/)

## Setup
```shell
# navigate to boot partition of the image
cd /media/$USER/boot/

# enable ssh
touch ssh

# create user nicof2000
echo "username:$(mkpasswd)" > userconf

# connect to wifi (optional)
cat <<_EOF > wpa_supplicant.conf
network={
	ssid="SSID"
	psk=WPA_PASSPHRASE
}
_EOF
```

## Runtime
### Disable HDMI port
Stop the TVService deamon using (add it to the file `/etc/rc.local` to do it on every startup):
```
/usr/bin/tvservice -o
```
You can reenable you hdmi port using `/usr/bin/tvservice -p`

### Disable LEDs
Add the following two lines to the file: `/boot/config.txt`
```
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
```

#### Set the Pi Zero ACT LED trigger to "none"
```
echo none | sudo tee /sys/class/leds/led0/trigger
```

#### Turn off the Pi Zero ACT LED
```
echo 1 | sudo tee /sys/class/leds/led0/brightness
```

#### Set yellow LED to "mmc0" and red LED to "heartbeat"
```
echo mmc0      | sudo tee /sys/class/leds/led0/trigger
echo heartbeat | sudo tee /sys/class/leds/led1/trigger
```
#### Reset yello and red led
```
echo mmc0  | sudo tee /sys/class/leds/led0/trigger
echo input | sudo tee /sys/class/leds/led1/trigger
```

### GPIO Shutdown
Restart: Connect the GPIO Pins 5 and 6 for one second.
Shutdown: Connect the GPIO Pins 5 and 6 for five seconds.
```
sudo wget -O /usr/local/bin/pishutdown.py http://raw.githubusercontent.com/gilyes/pi-shutdown/master/pishutdown.py
sudo git clone https://github.com/gilyes/pi-shutdown .
sudo cp 1722-144/pishutdown/* /etc/systemd/system
sudo systemctl enable pishutdown
sudo rm -rf pi-shutdown
```

### WiFi Access Point
```
# configure network in /etc/network/interfaces:
allow-hotplug <wlan1>
iface <wlan1> inet static
	wireless-power off
	address <ip>
	netmask <netmask>

# setup hostapd
cat <<_EOF > /etc/hostapd/hostapd.conf:
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
beacon_int=100
auth_algs=1
wpa_key_mgmt=WPA-PSK
ssid=<ESSID>
channel=4
hw_mode=g
wpa_passphrase=<PASSWORD>
rsn_pairwise=CCMP
interface=wlan0
wpa=2
country_code=DE
ieee80211n=1
_EOF

chmod 600 /etc/hostapd/hostapd.conf

# add to /etc/default/hostapd:
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

#### DHCP Server
```sh
cat <<_EOF >> /etc/dnsmasq.conf
interface=wlan1
dhcp-range=172.25.25.10,172.25.25.100,24,3h
dhcp-option=3,172.25.25.1
_EOF
```

### udev: Bind network device to specific name
```sh
# Deactivate "predictable naming" (default on RPI):
ln -s /dev/null /etc/systemd/network/99-default.link

# Add driver to /etc/udev/rules.d/72-static-name.rules (find drivername via "dmesg | grep -i usbcore"):
cat <<_EOF > /etc/udev/rules.d/72-static-name.rules
ACTION=="add", SUBSYSTEM=="net", DRIVERS=="brcmfmac",  NAME="wlan0"
ACTION=="add", SUBSYSTEM=="net", DRIVERS=="rt2800usb", NAME="wlan1"
ACTION=="add", SUBSYSTEM=="net", DRIVERS=="rtl8192cu", NAME="wlan2"
_EOF

# Or add Mac to /etc/udev/rules.d/72-static-name.rules:
cat <<_EOF > /etc/udev/rules.d/72-static-name.rules
ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="aa:bb:cc:dd:ee.ff", NAME="eth0"
ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="aa:bb:cc:dd:ee.ff", NAME="wlan1"
ACTION=="add", SUBSYSTEM=="net", ATTR{address}=="aa:bb:cc:dd:ee.ff", NAME="wlan0"
_EOF
```

### Raspbian 10 (Buster)
Wifi wont connect because `/etc/networks/interfaces` does not exist:
```
auto lo
iface lo inet loopback
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
  wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
```

### NDIS
see: https://learn.adafruit.com/turning-your-raspberry-pi-zero-into-a-usb-gadget/ethernet-gadget
```sh
# add to config.txt
dtoverlay=dwc2
```
```sh
# add after rootwait in cmdline.txt
modules-load=dwc2,g_ether
```
