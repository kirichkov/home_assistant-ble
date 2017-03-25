# HomeAssistant::Ble

Companion app from home-assistant sending BLE events.

Since HA does not cope well with bluetooth device tracking (https://home-assistant.io/components/device_tracker.bluetooth_le_tracker/) this app runs along home-assistant and sends device tracking to it.

## Installation


$ `gem install home_assistant-ble`

## Usage

Run `home_assistant-ble [your config file]` binary.

More instruction to launch this as a service with systemd (TODO).

## Configuration

```
interval: 30 # in seconds, interval between device scan
grace_period: 60 # in seconds, delay before considering a device has disappeared
home_assistant_url: http://localhost:8123 # url to contact home-assistant
home_assistant_password: xxxxx # a non mandatory password to authenticate to home-assistant api
home_assistant_devices: # devices whose activity will be sent to home-assistant.
  F0:5C:F4:EA:BF:C8: nut1 # [macaddress]: [identifier for home-assistant]
```

All presented settings (except `home_assistant_devices`) are set to their _default_  values. They don't need to be set.
