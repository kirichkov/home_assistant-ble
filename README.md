# HomeAssistant::Ble

[![Build Status](https://travis-ci.org/kamaradclimber/home_assistant-ble.svg?branch=master)](https://travis-ci.org/kamaradclimber/home_assistant-ble)
[![Gem Version](https://badge.fury.io/rb/home_assistant-ble.svg)](https://badge.fury.io/rb/home_assistant-ble)

Companion app from home-assistant sending BLE events.

Since HA does not cope well with bluetooth device tracking (https://home-assistant.io/components/device_tracker.bluetooth_le_tracker/) this app runs along home-assistant and sends device tracking to it.

## Installation

For raspbian install required packages:

    $ sudo apt-get install ruby-dev libcap-dev

Build the gem from source to use the latest version:

    $ git clone https://github.com/kirichkov/home_assistant-ble.git
    $ cd home_assistant-ble
    $ gem build home_assistant-ble.gemspec
    $ sudo gem install home_assistant-ble-1.4.2.gem

## Usage

Run `home_assistant-ble [your config file]` binary.

### Systemd

To launch as a systemd service, you can copy `home_assistant-ble.service` file present in this repo.

I'll probably build an archlinux package at some point (TODO).


### Non noot

Running as non-root on recent Raspbian, Ubuntu and Debian-based distros requires changes to DBus configuration and adding the user to the `bluetooth` group. For more information check this [stackexchange post](https://unix.stackexchange.com/questions/348441/how-to-allow-non-root-systemd-service-to-use-dbus-for-ble-operation/348449#348449).

Make sure you have the following in your `/etc/dbus-1/system.d/bluetooth.conf`:

    <!-- allow users of bluetooth group to communicate -->
    <policy group="bluetooth">
      <allow send_destination="org.bluez"/>
      <allow send_interface="org.bluez.GattCharacteristic1"/>
      <allow send_interface="org.bluez.GattDescriptor1"/>
      <allow send_interface="org.freedesktop.DBus.ObjectManager"/>
      <allow send_interface="org.freedesktop.DBus.Properties"/>
    </policy>

Then reload DBus:

    sudo service dbus reload

In other Linux distros to be able to run with a non-root user, read http://unix.stackexchange.com/questions/96106/bluetooth-le-scan-as-non-root. In short (adapt if using a non-debian distribution):

```
sudo apt install libcap2-bin
sudo setcap 'cap_net_raw,cap_net_admin+eip' `readlink -f \`which ruby\``
```
**Note**: these instructions are probably not sufficient, see https://github.com/kamaradclimber/home_assistant-ble/issues/1

### Configuration

```
interval: 30                              # in seconds, interval between device scan. Defaults to 30
grace_period: 60                          # in seconds, delay before considering a device has disappeared. Defaults to 60
home_assistant_url: http://localhost:8123 # url to contact home-assistant. Defaults to http://localhost:8123
home_assistant_token: token               # Long lived access token if you're using the `homeassistant` http auth type.
home_assistant_password: xxxxx            # non mandatory password to authenticate to home-assistant api. Default is nil. If `home_assistant_token` is provided this setting has no effect
home_assistant_devices:                   # devices whose activity will be sent to home-assistant. Default is empty (no tracked devices)
  F0:5C:F4:EA:BF:C8: nut1                 # [macaddress]: [identifier for home-assistant]

home_assistant_devices_file: /var/lib/hass/known_devices.yaml # read devices whose activity will be sent to home-assistant. Default is empty (devices from home-assistant are not tracked). This can easily replace home_assistant_devices setting.
```
