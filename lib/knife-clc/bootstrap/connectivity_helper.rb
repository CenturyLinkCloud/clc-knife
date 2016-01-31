require 'net/ssh'
require 'socket'

class ConnectivityHelper
  def test_tcp(params)
    host = params.fetch(:host)
    port = params.fetch(:port)

    socket = TCPSocket.new(host, port)
    if readable = IO.select([socket], [socket], nil, 5)
      yield if block_given?
      true
    else
      false
    end
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError, Errno::EPERM, Errno::ETIMEDOUT
    false
  ensure
    socket && socket.close
  end

  def test_ssh_tunnel(params)
    host = params.fetch(:host)
    port = params.fetch(:port)
    gateway = params.fetch(:gateway)

    gateway_user, gateway_host = gateway.split('@')
    gateway_host, gateway_port = gateway_host.split(':')

    gateway = Net::SSH::Gateway.new(gateway_host, gateway_user, :port => gateway_port || 22)
    status = false
    gateway.open(host, port) do |local_tunnel_port|
      status = test_tcp(:host => 'localhost', :port => local_tunnel_port)
    end
    status
  rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError, Errno::EPERM, Errno::ETIMEDOUT
    false
  end
end
