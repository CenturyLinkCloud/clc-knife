require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcTemplateList < Knife
      include Knife::ClcBase

      banner 'knife clc template list (options)'

      def run
        $stdout.sync = true

        templates = connection.list_templates('ca1')

        all_properties = ['name', 'osType', 'description', 'storageSizeGB', 'capabilities', 'apiOnly']

        puts Formatador.display_table(templates, all_properties[0..2])
      end
    end
  end
end
