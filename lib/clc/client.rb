require 'faraday'
require 'faraday_middleware'
require 'logger'

module Clc
  class Client
    attr_reader :account
    attr_reader :connection

    def initialize(params = {})
      @connection = Faraday.new(:url => 'https://api.ctl.io') do |builder|
        builder.use Clc::CloudExceptions::Handler
        builder.request :json
        builder.response :json
        builder.adapter Faraday.default_adapter
      end

      setup_logging(@connection.builder, params[:verbosity]) if params[:verbosity]

      response = @connection.post(
        '/v2/authentication/login',
        'username' => params[:username] || ENV['CLC_USERNAME'],
        'password' => params[:password] || ENV['CLC_PASSWORD']
      )

      @connection.authorization :Bearer, response.body.fetch('bearerToken')

      @account = response.body.fetch('accountAlias')
    end

    def list_datacenters
      connection.get("v2/datacenters/#{@account}").body
    end

    def show_datacenter(id, group_links = true)
      connection.get("v2/datacenters/#{@account}/#{id}?groupLinks=#{group_links}").body
    end

    def list_servers(datacenter_id = 'ca1')
      datacenter = show_datacenter(datacenter_id)

      group_links = datacenter['links'].select { |l| l['rel'] == 'group' }

      groups = group_links.map do |link|
        connection.get(link['href']).body
      end

      links = find_server_links(groups)

      links.map do |link|
        connection.get(link['href']).body
      end
    end

    def show_server(id)
      connection.get("/v2/servers/#{@account}/#{id}").body
    end

    def find_server_links(groups)
      groups.map do |group|
        if group['serversCount'] > 0
          servers = group['links'].select { |link| link['rel'] == 'server' }
          servers + find_server_links(group['groups'])
        end
      end.flatten.compact
    end

    # TODO: Takes a lot of time
    def create_server(params = {})
      operation_info = connection.post("/v2/servers/#{account}", params).body
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      server_link = operation_info['links'].find { |link| link['rel'] == 'self' }
      wait_for_operation(operation['id'], 360)

      connection.get(server_link['href']).body
    end

    def delete_server(id)
      operation_info = connection.delete("v2/servers/#{account}/#{id}").body
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    # TODO: Reset is quicker. Probably 'hard-reset'
    def reset_server(id)
      response = connection.post("/v2/operations/#{account}/servers/reset", [id])
      operation_info = response.body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    # TODO: Reboot is slower. Looks like OS-level reboot
    def reboot_server(id)
      response = connection.post("/v2/operations/#{account}/servers/reboot", [id])
      operation_info = response.body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    def power_on_server(id)
      response = connection.post("/v2/operations/#{account}/servers/powerOn", [id])
      operation_info = response.body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    def power_off_server(id)
      response = connection.post("/v2/operations/#{account}/servers/powerOff", [id])
      operation_info = response.body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    def list_templates(datacenter_id)
      url = "/v2/datacenters/#{account}/#{datacenter_id}/deploymentCapabilities"
      connection.get(url).body.fetch('templates')
    end

    # Possible options?...
    # 1. Select internal IP to map to public. Optional
    # 2. Ports which are allowed to be accessed. Required.
    # 3. Source limitations. Optional

    # Protocol values: "tcp", "udp", or "icmp".
    # TODO: Takes quite a lot of time...
    def add_public_ip(server_id)
      operation = connection.post(
        "/v2/servers/#{account}/#{server_id}/publicIPAddresses",
        'ports' => [{ 'protocol' => 'tcp', 'port' => '80' }]
      ).body
      wait_for_operation(operation['id'])
    end

    # TODO: Takes quite a lot of time...
    def remove_public_ip(server_id, ip_string)
      url = "/v2/servers/#{account}/#{server_id}/publicIPAddresses/#{ip_string}"
      operation = connection.delete(url).body
      wait_for_operation(operation['id'])
    end

    def get_operation_status(id)
      connection.get("v2/operations/#{account}/status/#{id}").body.fetch('status')
    end

    def show_group(id)
      connection.get("v2/groups/#{account}/#{id}").body
    end

    def list_groups(datacenter_id)
      datacenter = show_datacenter(datacenter_id, true)

      root_group_link = datacenter['links'].detect { |link| link['rel'] == 'group' }

      flatten_groups(show_group(root_group_link['id']))
    end

    def wait_for_operation(id, timeout = 60)
      expire_at = Time.now + timeout
      loop do
        case status = get_operation_status(id)
        when 'succeeded' then return true
        when 'failed', 'unknown' then raise 'Operation Failed' # reason?
        when 'executing', 'resumed', 'notStarted'
          raise 'Operation takes too much time to complete' if Time.now > expire_at
          next sleep(2)
        else
          raise "Operation status unknown: #{status}"
        end
      end
    end

    private

    def setup_logging(builder, verbosity)
      case verbosity
      when 1
        builder.response :logger, ::Logger.new(STDOUT)
      when 2
        builder.response :logger, ::Logger.new(STDOUT), :bodies => true
      end
    end

    def flatten_groups(group)
      child_groups = group.delete('groups')
      return [group] unless child_groups && child_groups.any?
      [group] + child_groups.map { |child| flatten_groups(child) }.flatten
    end
  end
end
