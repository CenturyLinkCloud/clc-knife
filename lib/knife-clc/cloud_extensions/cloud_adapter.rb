module Knife
  module Clc
    module CloudExtensions
      class CloudAdapter < SimpleDelegator
        attr_reader :connection

        def initialize(params)
          @connection = params.fetch(:connection)
          super(@connection)
        end

        def get_server_credentials(server)
          creds_link = server['links'].find { |link| link['rel'] == 'credentials' }
          connection.follow(creds_link) if creds_link
        end

        def ensure_server_powered_on(server)
          return unless server['details']['powerState'] == 'stopped'
          links = connection.power_on_server(server['id'])
          connection.wait_for(links['operation']['id'])
        end

        def get_private_ip(server)
          private_ips = server['details']['ipAddresses'].map { |addr| addr['internal'] }.compact
          private_ips.first
        end

        def get_public_ip(server)
          public_ips = server['details']['ipAddresses'].map { |addr| addr['public'] }.compact
          public_ips.first
        end
      end
    end
  end
end
