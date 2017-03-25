require 'home_assistant/ble/version'
require 'ble'
require 'mash'

module HomeAssistant
  module Ble
    class Detector
      attr_reader :config, :known_devices

      def initialize(config)
        @config = Mash.new(config)
        @known_devices = {}
      end

      # polling interval
      def interval
        config['interval'] || 30
      end

      # time after which a device is considered as disappeared
      def grace_period
        config['grace_period'] || 60
      end

      def run
        loop do
          detect_devices
          clean_devices
          debug "Will sleep #{interval}s before relisting devices"
          sleep interval
        end
      end

      private

      def log(message)
        puts message
      end

      def debug(message)
        puts message
      end

      def detect_devices
        adapter.devices.each do |name|
          log "Just discovered #{name}" unless known_devices.key?(name)
          known_devices[name] = Time.now
        end
      end

      def clean_devices
        disappeared = (known_devices.keys - adapter.devices).select do |name|
          Time.now - known_devices[name] > grace_period
        end
        disappeared.each do |name|
          known_devices.delete(name).tap do |last_seen|
            log "#{name} has disappeared (last seen #{last_seen})"
          end
        end
      end

      def adapter
        @adapter ||= begin
                       iface = BLE::Adapter.list.first
                       debug "Selecting #{iface} to listen for bluetooth events"
                       raise 'Unable to find a bluetooth device' unless iface
                       BLE::Adapter.new(iface).tap do |a|
                         debug 'Activating discovery'
                         a.start_discovery
                       end
                     end
      end
    end
  end
end
