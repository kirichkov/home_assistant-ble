# HomeAssistant::Ble

[![Build Status](https://travis-ci.org/kamaradclimber/home_assistant-ble.svg?branch=master)](https://travis-ci.org/kamaradclimber/home_assistant-ble)
[![Gem Version](https://badge.fury.io/rb/home_assistant-ble.svg)](https://badge.fury.io/rb/home_assistant-ble)

Companion app from home-assistant sending BLE events.

Since HA does not cope well with bluetooth device tracking (https://home-assistant.io/components/device_tracker.bluetooth_le_tracker/) this app runs along home-assistant and sends device tracking to it.

## Installation

For raspbian install required packages:

    $ sudo apt-get install ruby-dev libcap-dev

    $ gem install home_assistant-ble

## Usage

Run `home_assistant-ble -c [your config file]` binary.

The following command line options are recognized

    -c CONFIG_FILE  - location of the config file
    -v              - verbose
    -f              - run in foreground
    -p PID_FILE     - where to write the PID file

### Systemd

To launch as a systemd service, you can copy `home_assistant-ble.service` file present in this repo. 
If you want to run the service using a different user/group you need to make sure that the PID file can be written to /run. By default the run directory is writable only by root, so you will need to write the PID at a different location.

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
interval: 30                              # in seconds, interval between device scan. Defaults to 30
grace_period: 60                          # in seconds, delay before considering a device has disappeared. Defaults to 60
home_assistant_url: http://localhost:8123 # url to contact home-assistant. Defaults to http://localhost:8123
home_assistant_password: xxxxx            # non mandatory password to authenticate to home-assistant api. Default is nil
home_assistant_devices:                   # devices whose activity will be sent to home-assistant. Default is empty (no tracked devices)
  F0:5C:F4:EA:BF:C8: nut1                 # [macaddress]: [identifier for home-assistant]

home_assistant_devices_file: /var/lib/hass/known_devices.yaml # read devices whose activity will be sent to home-assistant. Default is empty (devices from home-assistant are not tracked). This can easily replace home_assistant_devices setting.
```
