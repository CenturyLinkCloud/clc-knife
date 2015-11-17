require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcDatacenterShow < Knife
      include Knife::ClcBase

      banner 'knife clc datacenter show (options)'

      def run
        $stdout.sync = true

        datacenter = connection.show_datacenter(name_args[0])

        puts "#{ui.color("ID:", :green)} #{datacenter['id']}"
        puts "#{ui.color("Name:", :green)} #{datacenter['name']}"
        puts "#{ui.color("Links:", :green)}"
        puts Formatador.display_table(datacenter['links'], ['rel', 'href'])
      end
    end
  end
end
