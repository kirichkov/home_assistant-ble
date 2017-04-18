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
            mac = conf['mac'].gsub(/^(ble_|bt_)/i, '').upcase
            conf['dev_id'] = name
            devices[mac] = conf.select { |k, _v| %w(dev_id mac name).include? k }
            debug "Adding #{mac} (#{conf['name']}) found in known_devices.yaml"
          end
        end
        if config['home_assistant_devices']
          config['home_assistant_devices'].each do |mac, _name|
            ble_mac = "BLE_#{mac.upcase}" unless mac =~ /^(ble_|bt_)/i
            devices[mac] = Mash.new(mac: ble_mac)
          end
        end

        devices
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

      def update_home_assistant(ha_conf, state)
        ha_conf['location_name'] = state
        uri = URI.join(home_assistant_url, '/api/services/device_tracker/see')
        request = Net::HTTP::Post.new(uri)
        request.content_type = 'application/json'
        request['X-Ha-Access'] = home_assistant_password if home_assistant_password
        request.body = ha_conf.to_json
        req_options = { use_ssl: uri.scheme == 'https' }

        begin
          response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(request)
          end
        rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
               Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
               Net::ProtocolError, Errno::ECONNREFUSED => e
          log "Could not update HA: #{e.message}"
          return
        end

        if response.code.to_i == 200
          debug "State update #{state} sent to HA for #{ha_conf['dev_id']}"
          debug response.body
        else
          log "Error while sending #{state} to HA form #{ha_conf['dev_id']}."
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
