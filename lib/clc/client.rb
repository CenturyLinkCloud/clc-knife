require 'faraday'
require 'faraday_middleware'
require 'logger'

module Clc
  class Client
    attr_reader :account
    attr_reader :connection

    def initialize(params = {})
      @connection = Faraday.new(:url => params[:endpoint] || 'https://api.ctl.io') do |builder|
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
        group = connection.get("v2/groups/#{@account}/#{link['id']}?serverDetail=detailed").body
        flatten_groups(group)
      end.flatten

      groups.map { |group| group['servers'] }.flatten.compact
    end

    def show_server(id, uuid = false)
      connection.get("/v2/servers/#{@account}/#{id}?uuid=#{uuid}").body
    end

    # TODO: Takes a lot of time
    def create_server(params)
      body = connection.post("/v2/servers/#{account}", params).body
      async_response(body)
    end

    def delete_server(id)
      body = connection.delete("v2/servers/#{account}/#{id}").body
      async_response(body)
    end

    # TODO: Reset is quicker. Probably 'hard-reset'
    def reset_server(id)
      response = connection.post("/v2/operations/#{account}/servers/reset", [id])
      body = response.body.first
      async_response(body)
    end

    # TODO: Reboot is slower. Looks like OS-level reboot
    def reboot_server(id)
      response = connection.post("/v2/operations/#{account}/servers/reboot", [id])
      body = response.body.first
      async_response(body)
    end

    def power_on_server(id)
      response = connection.post("/v2/operations/#{account}/servers/powerOn", [id])
      body = response.body.first
      async_response(body)
    end

    def power_off_server(id)
      response = connection.post("/v2/operations/#{account}/servers/powerOff", [id])
      body = response.body.first
      async_response(body)
    end

    def list_templates(datacenter_id)
      url = "/v2/datacenters/#{account}/#{datacenter_id}/deploymentCapabilities"
      connection.get(url).body.fetch('templates')
    end

    def create_ip_address(server_id, params)
      body = connection.post(
        "/v2/servers/#{account}/#{server_id}/publicIPAddresses",
        params
      ).body

      async_response('links' => [body])
    end

    def delete_ip_address(server_id, ip_string)
      url = "/v2/servers/#{account}/#{server_id}/publicIPAddresses/#{ip_string}"
      body = connection.delete(url).body

      async_response('links' => [body])
    end

    def list_ip_addresses(server_id)
      server = show_server(server_id)

      ip_links = server['links'].select do |link|
        link['rel'] == 'publicIPAddress'
      end

      ip_links.map { |link| follow(link).merge('id' => link['id']) }
    end

    def show_operation(id)
      connection.get("v2/operations/#{account}/status/#{id}").body
    end

    def show_group(id, params = {})
      connection.get("v2/groups/#{account}/#{id}", params).body
    end

    def list_groups(datacenter_id)
      datacenter = show_datacenter(datacenter_id, true)

      root_group_link = datacenter['links'].detect { |link| link['rel'] == 'group' }

      flatten_groups(show_group(root_group_link['id']))
    end

    def create_group(params)
      connection.post("/v2/groups/#{account}", params).body
    end

    def follow(link)
      connection.get(link['href']).body
    end

    def execute_package(params)
      response = connection.post("/v2/operations/#{account}/servers/executePackage", params)
      response.body
    end

    def wait_for(operation_id, timeout = 1200)
      expire_at = Time.now + timeout
      loop do
        operation = show_operation(operation_id)
        status = operation['status']
        yield status if block_given?

        case status
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

    def async_response(body)
      check_errors(body)
      extract_links(body)
    end

    def check_errors(body)
      if error = body['errorMessage']
        raise error
      elsif body['isQueued'] == false
        raise 'Cloud refused to queue the operation'
      end
    end

    def extract_links(body)
      links = body['links']
      {
        'resource' => links.find { |link| link['rel'] == 'self' },
        'operation' => links.find { |link| link['rel'] == 'status' }
      }.keep_if { |_, value| value }
    end

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
