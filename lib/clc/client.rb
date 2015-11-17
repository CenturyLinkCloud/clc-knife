require 'faraday'
require 'faraday_middleware'
require 'logger'

module Clc
  class Client
    attr_reader :account
    attr_reader :connection

    def initialize(params = {})
      @connection = Faraday.new(:url => 'https://api.ctl.io') do |builder|
        builder.request :json
        builder.response :json
        # TODO AS: One level lower...
        builder.response :logger, ::Logger.new(STDOUT), :bodies => true
        builder.adapter Faraday.default_adapter
      end

      response = @connection.post('/v2/authentication/login', {
        'username' => params[:username] || ENV['CLC_USERNAME'],
        'password' => params[:password] || ENV['CLC_PASSWORD']
      })

      @connection.authorization :Bearer, response.body.fetch('bearerToken')

      @account = response.body.fetch('accountAlias')
    end

    def list_datacenters
      connection.get("v2/datacenters/#{@account}").body
    end

    def show_datacenter(id)
      connection.get("v2/datacenters/#{@account}/#{id}?groupLinks=true").body
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

    # TODO AS: Takes a lot of time
    def create_server(params = {})
      params['name'] ||= 'req' # Required. String. Should be uniq string 1-8 chars long
      params['groupId'] ||= '975a79f94b84452ea1c920325967a33c' # Required. Id of the parent group
      params['sourceServerId'] ||= 'CENTOS-6-64-TEMPLATE' # Required. String. Id of either template or another machine. Ignored for Bare-Metal.
      params['cpu'] ||= '1' # Required. Integer. 1-16. Ignored for Bare-Metal.
      params['memoryGB'] ||= '1' # Required. Integer. 1-128. Memory in GBs. Ignored for Bare-Metal.
      params['type'] ||= 'standard' # Required. String. Allowed values: standard, hyperscale, bareMetal

      # params['configurationId'] ||= 'some-config-id' # Required for BareMetal.
      # params['osType'] ||= %w(redHat6_64Bit centOS6_64Bit windows2012R2Standard_64Bit windows2012R2Datacenter_64Bit ubuntu14_64Bit).sample # Required for BareMetal.

      # params['description'] ||= 'sample description' # Optional. String. Default: empty?
      # params['isManagedOS'] ||= 'isManagedOS' # Optional. Boolean. Default: false. Ignored for Bare-Metal.
      # params['isManagedBackup'] ||= 'isManagedBackup' # Optional. Boolean. Default: ?. Requires 'isManagedOS'. Ignored for Bare-Metal.
      # params['primaryDns'] ||= 'address of primary dns server' # Optional. String. Default: value from account.
      # params['secondaryDns'] ||= 'address of secondary dns server' # Optional. String. Default: value from account.
      # params['networkId'] ||= 'id of the network to launch machine in' # Optional. String. Will create network if you haven't any.
      # params['ipAddress'] ||= '10.0.0.1' # Optional. String. Public/Private?? Ignored for Bare-Metal.
      # params['password'] ||= 'rOotp@$$w0rd' # Optional. String. Default: Automatic generation.
      # params['sourcePassword'] ||= 'rOotp@$$w0rd' # Optional. String. Used if you clone a server.
      # params['cpuAutoscalePolicyId'] ||= 'somecrazyid' # Optional. String. Id of scaling policy.
      # params['storageType'] ||= 'standard' # Optional. String. Default: premium. For standard machines: standard or premium. For hyperscale: hyperscale.  Ignored for Bare-Metal.
      # params['antiAffinityPolicyId'] ||= 'id-of-anti-affinity-policy' # Optional. String. Actual for hyperscale machines only.
      # params['customFields'] ||= [{ 'customKey' => 'customValue'}] # Optional. Hash. Seems-like a metadata.
      # params['additionalDisks'] ||= [{ 'path' => '/dev/sdb1', 'sizeGB' => '10', 'type' => 'raw' | 'partitioned' }] # Optional. Hash. Set of storage params. Ignored for Bare-Metal.
      # params['ttl'] ||= '2014-12-17T01:17:17Z' # Optional. DateTime. Schedule server deletion. Ignored for Bare-Metal.
      # params['packages'] ||= [{ 'packageId' => 'someId', 'parameters' => [{ 'a' => 'b' }] }] # Optional. Hash. Run some packages (?) on server after it's launched.  Ignored for Bare-Metal.

      operation_info = connection.post("/v2/servers/#{account}", params).body
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'], 360)
    end

    def delete_server(id)
      operation_info = connection.delete("v2/servers/#{account}/#{id}").body
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    # TODO AS: Reset is quicker. Probably 'hard-reset'
    def reset_server(id)
      operation_info = connection.post("/v2/operations/#{account}/servers/reset", [id]).body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    # TODO AS: Reboot is slower. Looks like OS-level reboot
    def reboot_server(id)
      operation_info = connection.post("/v2/operations/#{account}/servers/reboot", [id]).body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    def power_on_server(id)
      operation_info = connection.post("/v2/operations/#{account}/servers/powerOn", [id]).body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    def power_off_server(id)
      operation_info = connection.post("/v2/operations/#{account}/servers/powerOff", [id]).body.first
      operation = operation_info['links'].find { |link| link['rel'] == 'status' }
      wait_for_operation(operation['id'])
    end

    def list_templates(datacenter_id)
      connection.get("/v2/datacenters/#{account}/#{datacenter_id}/deploymentCapabilities").body['templates']
    end

    # Possible options?...
    # 1. Select internal IP to map to public. Optional
    # 2. Ports which are allowed to be accessed. Required.
    # 3. Source limitations. Optional

    # Protocol values: "tcp", "udp", or "icmp".
    # TODO AS: Takes quite a lot of time...
    def add_public_ip(server_id)
      operation = connection.post("/v2/servers/#{account}/#{server_id}/publicIPAddresses", {
        'ports' => [{ 'protocol' => 'tcp', 'port' => '80'}]
      }).body
      wait_for_operation(operation['id'])
    end

    # TODO AS: Takes quite a lot of time...
    def remove_public_ip(server_id, ip_string)
      operation = connection.delete("/v2/servers/#{account}/#{server_id}/publicIPAddresses/#{ip_string}").body
      wait_for_operation(operation['id'])
    end

    def get_operation_status(id)
      connection.get("v2/operations/#{account}/status/#{id}").body.fetch('status')
    end

    def wait_for_operation(id, timeout = 60)
      expire_at = Time.now + timeout
      while true
        case status = get_operation_status(id)
        when 'succeeded' then return true
        when 'failed', 'unknown' then raise 'Operation Failed' #reason?
        when 'executing', 'resumed', 'notStarted'
          raise 'Operation takes too much time to complete' if Time.now > expire_at
          next sleep(2)
        else
          raise "Operation status unknown: #{status}"
        end
      end
    end

  end
end
