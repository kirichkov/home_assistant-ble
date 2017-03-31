require 'home_assistant/ble/version'
require 'ble'
require 'mash'
require 'net/http'
require 'uri'
require 'json'
require 'cap2'
require 'digest/md5'

module HomeAssistant
  module Ble
    class Detector
      attr_reader :config, :known_devices

      def initialize(config)
        @config = Mash.new(config)
        @known_devices = {}
      end

      def discovery_time
        config['discovery_time'] || 60
      end

      # polling interval
      def interval
        config['interval'] || 30
      end

      # time after which a device is considered as disappeared
      def grace_period
        config['grace_period'] || 60
      end

      def home_assistant_url
        config['home_assistant_url'] || 'http://localhost:8123'
      end

      def home_assistant_password
        config['home_assistant_password']
      end

      def home_assistant_devices
        devices = {}
        if  config['home_assistant_devices_file']
          YAML.load_file(config['home_assistant_devices_file']).each do |name, conf|
            next unless conf['mac'] =~ /^(ble_|bt_)/i
            next unless conf['track']
            mac = conf.delete('mac').gsub(/^(ble_|bt_)/i, '').upcase
            conf['name'] = name # erase name with HA id
            devices[mac] = conf
            debug "Adding #{mac} (#{name}) found in known_devices.yaml"
          end
        end
        if config['home_assistant_devices']
          config['home_assistant_devices'].each do |mac, name|
            devices[mac] = Mash.new( name: name )
          end
        end

        return devices
      end

      def run
        loop do
          discover
          detect_new_devices
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
        log 'Set DEBUG environment variable to activate debug logs' unless ENV['DEBUG'] || @debug_tip
        @debug_tip = true
        return unless ENV['DEBUG']
        print '(debug) '
        puts message
      end

      def detect_new_devices
        adapter.devices.each do |name|
          unless known_devices.key?(name)
            log "Just discovered #{name}"
            home_assistant_devices[name] && update_home_assistant(home_assistant_devices[name], :home)
          end
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
            home_assistant_devices[name] && update_home_assistant(home_assistant_devices[name], :not_home)
          end
        end
      end

      def state_update(ha_conf, state)
        attributes = {}
        attributes['entity_picture'] = ha_conf['picture']
        if ha_conf['gravatar']
          hash = Digest::MD5.hexdigest(ha_conf['gravatar'].downcase)
          attributes['entity_picture'] = "https://www.gravatar.com/avatar/#{hash}"
        end
        JSON.dump('state' => state, 'attributes' => attributes)
      end

      def update_home_assistant(ha_conf, state)
        ha_name = ha_conf['name']
        uri = URI.join(home_assistant_url, "api/states/device_tracker.#{ha_name}")
        request = Net::HTTP::Post.new(uri)
        request.content_type = 'application/json'
        request['X-Ha-Access'] = home_assistant_password if home_assistant_password
        request.body = state_update(ha_conf, state) 
        req_options = { use_ssl: uri.scheme == 'https' }

        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end

        if response.code.to_i == 200
          debug "State update #{state} sent to HA for #{ha_name}"
          debug response.body
        else
          log "Error while sending #{state} to HA form #{ha_name}."
          log "URI was: #{uri}. Response was:"
          log response.body
        end
      end

      def adapter
        @adapter ||= begin
                       ensure_rights!
                       iface = BLE::Adapter.list.first
                       debug "Selecting #{iface} to listen for bluetooth events"
                       raise 'Unable to find a bluetooth device' unless iface
                       BLE::Adapter.new(iface)
                     end
      end

      def discover
        debug 'Cleaning old devices'
        adapter.devices.dup.each do |d|
          adapter[d].remove
        end
        debug 'Activating discovery'
        adapter.start_discovery
        debug 'Sleeping a bit to discover devices'
        sleep discovery_time
        adapter.stop_discovery
      end

      def ensure_rights!
        BLE::Adapter.list.first
      rescue DBus::Error => e
        raise unless e.message =~ /DBus.Error.AccessDenied/
        log 'Not enough rights to use bluetooth device, read https://github.com/kamaradclimber/home_assistant-ble'
        log 'See also https://github.com/kamaradclimber/home_assistant-ble/issues/1'
        log 'Current capabilities:'
        log Cap2.process.inspect
        exit 1
      end
    end
  end
end
