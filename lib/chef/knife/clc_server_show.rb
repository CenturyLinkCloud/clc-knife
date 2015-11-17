require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcServerShow < Knife
      include Knife::ClcBase

      banner 'knife clc server show (options)'

      def run
        $stdout.sync = true

        server = connection.show_server(name_args[0])

        puts server.inspect

        properties = %w(id name description groupId locationId osType status)

        properties.each do |prop|
          puts "#{ui.color(prop.capitalize + ":", :green)} #{server[prop]}"
        end

        details = %w(cpu memoryMB storageGB)

        details.each do |prop|
          puts "#{ui.color(prop.capitalize + ":", :green)} #{server['details'][prop]}"
        end

        puts "#{ui.color("Links:", :green)}"
        puts Formatador.display_table(server['links'], ['rel', 'href'])
      end
    end
  end
end
