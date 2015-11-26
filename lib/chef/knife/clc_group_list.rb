require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcGroupList < Knife
      include Knife::ClcBase

      banner 'knife clc template list (options)'

      option :clc_datacenter,
        :long => '--datacenter ID',
        :short => '-D ID',
        :description => 'Datacenter ID to show templates from'

      option :clc_view,
        :long => '--view VIEW',
        :default => 'tree',
        :description => 'Display output either as a table or a tree'

      def run
        $stdout.sync = true
        validate!
        render
      end

      def validate!
        errors = []

        unless config[:clc_datacenter]
          errors << 'Datacenter option is required'
        end

        unless ['tree', 'table'].include?(config[:clc_view])
          errors << 'View parameter should be either table or a tree'
        end

        if errors.any?
          errors.each { |message| ui.error message }
          show_usage
          exit 1
        end
      end

      def filters
        {
          'serversCount' => ->(count) { count.zero? ? '-' : count },
          'parentId' => ->(id) { id ? id : '-' }
        }
      end

      def width_limits
        {
          'description' => 0.2
        }
      end

      def fields
        %w(name id parentId description serversCount type status)
      end

      def headers
        {
          'name' => 'Name',
          'id' => 'ID',
          'parentId' => 'Parent ID',
          'description' => 'Description',
          'serversCount' => 'Servers',
          'type' => 'Type',
          'status' => 'Status'
        }
      end

      # {"id"=>"5ffda89a8ce6444baa8d28b9d1581e6d",
      #  "name"=>"CA1 Hardware",
      #  "description"=>"CA1 Hardware",
      #  "locationId"=>"CA1",
      #  "type"=>"default",
      #  "status"=>"active",
      #  "serversCount"=>0,
      #  "customFields"=>[],
      #  "links"=>
      #    [{"rel"=>"createGroup", "href"=>"/v2/groups/altd", "verbs"=>["POST"]}}
      # {"id"=>"5f69973e31d34bbbb76b0e1542b3a93a",
      #   "name"=>"Archive",
      #   "description"=>"Pay only for the storage consumed by the archived server. No compute or licensing costs are incurred.",
      #   "locationId"=>"CA1",
      #   "type"=>"archive",
      #   "status"=>"active",
      #   "serversCount"=>0,
      #   "links"=>[{"rel"=>"self", "href"=>"/v2/groups/altd/5f69973e31d34bbbb76b0e1542b3a93a", "verbs"=>["GET", "PATCH"]},
      #   {"rel"=>"parentGroup", "href"=>"/v2/groups/altd/5ffda89a8ce6444baa8d28b9d1581e6d", "id"=>"5ffda89a8ce6444baa8d28b9d1581e6d"},
      #   {"rel"=>"defaults", "href"=>"/v2/groups/altd/5f69973e31d34bbbb76b0e1542b3a93a/defaults", "verbs"=>["GET", "POST"]},
      #   {"rel"=>"billing", "href"=>"/v2/groups/altd/5f69973e31d34bbbb76b0e1542b3a93a/billing"}],
      #   "changeInfo"=>{"createdBy"=>"idrabenia", "createdDate"=>"2015-03-26T23:59:26Z",
      #     "modifiedBy"=>"idrabenia", "modifiedDate"=>"2015-03-26T23:59:26Z"}, "customFields"=>[]}

      def render
        case config[:clc_view]
        when 'tree' then render_tree
        when 'table' then render_table
        else
          ui.error "Unknown view: #{config[:clc_view]}"
          exit 1
        end
      end

      def data
        @data ||= connection.list_groups(config[:clc_datacenter]).map do |group|
          parent_link = group['links'].find { |link| link['rel'] == 'parentGroup' }
          group['parentId'] = parent_link['id'] if parent_link
          group
        end
      end

      def render_tree
        display_value = ->(group) { "#{group['name']} (#{group['id']})" }

        group_children = ->(parent_group) do
          data.select { |group| group['parentId'] == parent_group['id'] }
        end

        root = data.find { |group| group['parentId'].nil? }

        output = Hirb::Helpers::ParentChildTree.render(root,
          :type => :directory,
          :value_method => display_value,
          :children_method => group_children)

        puts output
      end

      def render_table
        output = Hirb::Helpers::AutoTable.render(data,
          :fields => fields,
          :headers => headers,
          :filters => filters,
          :max_fields => width_limits,
          :resize => false,
          :description => false)

        puts output
      end
    end
  end
end
