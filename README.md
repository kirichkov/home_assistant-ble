# HomeAssistant::Ble

[![Build Status](https://travis-ci.org/kamaradclimber/home_assistant-ble.svg?branch=master)](https://travis-ci.org/kamaradclimber/home_assistant-ble)
[![Gem Version](https://badge.fury.io/rb/home_assistant-ble.svg)](https://badge.fury.io/rb/home_assistant-ble)

Companion app from home-assistant sending BLE events.

Since HA does not cope well with bluetooth device tracking (https://home-assistant.io/components/device_tracker.bluetooth_le_tracker/) this app runs along home-assistant and sends device tracking to it.

## Installation


$ `gem install home_assistant-ble`

## Usage

Run `home_assistant-ble [your config file]` binary.

### Systemd

To launch as a systemd service, you can copy `home_assistant-ble.service` file present in this repo.

I'll probably build an archlinux package at some point (TODO).


### Non noot
To be able to run with a non-root user, read http://unix.stackexchange.com/questions/96106/bluetooth-le-scan-as-non-root. In short (adapt if using a non-debian distribution):

```
sudo apt install libcap2-bin
sudo setcap 'cap_net_raw,cap_net_admin+eip' `readlink -f \`which ruby\``
```
**Note**: these instructions are probably not sufficient, see https://github.com/kamaradclimber/home_assistant-ble/issues/1

### Configuration

```
interval: 30                              # in seconds, interval between device scan
grace_period: 60                          # in seconds, delay before considering a device has disappeared
home_assistant_url: http://localhost:8123 # url to contact home-assistant
home_assistant_password: xxxxx            # non mandatory password to authenticate to home-assistant api
home_assistant_devices:                   # devices whose activity will be sent to home-assistant.
  F0:5C:F4:EA:BF:C8: nut1                 # [macaddress]: [identifier for home-assistant]
```

All presented settings (except `home_assistant_devices`) are set to their _default_  values. They don't need to be set.
