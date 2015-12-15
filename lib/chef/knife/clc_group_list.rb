require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcGroupList < Knife
      include Knife::ClcBase

      banner 'knife clc group list (options)'

      option :clc_datacenter,
        :long => '--datacenter ID',
        :short => '-D ID',
        :description => 'Datacenter ID to show templates from',
        :on => :head

      option :clc_view,
        :long => '--view VIEW',
        :default => 'tree',
        :description => 'Display output either as a table or a tree',
        :on => :head

      def parse_and_validate_parameters
        unless config[:clc_datacenter]
          errors << 'Datacenter ID is required'
        end

        unless %w(tree table).include?(config[:clc_view])
          errors << 'View parameter should be either table or a tree'
        end
      end

      def execute
        context[:groups] = connection.list_groups(config[:clc_datacenter]).map do |group|
          parent_link = group['links'].find { |link| link['rel'] == 'parentGroup' }
          group['parentId'] = parent_link['id'] if parent_link
          group
        end

        render
      end

      def filters
        {
          'serversCount' => ->(count) { count.zero? ? '-' : count },
          'parentId' => ->(id) { id ? id : '-' },
          'description' => ->(description) { description.to_s.empty? ? '-' : description }
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
          'parentId' => 'Parent',
          'description' => 'Description',
          'serversCount' => 'Servers',
          'type' => 'Type',
          'status' => 'Status'
        }
      end

      def render
        case config[:clc_view]
        when 'tree' then render_tree
        when 'table' then render_table
        end
      end

      def render_tree
        display_value = ->(group) { "#{group['name']} (#{group['id']})" }

        group_children = ->(parent_group) do
          context[:groups].select { |group| group['parentId'] == parent_group['id'] }
        end

        root = context[:groups].find { |group| group['parentId'].nil? }

        return unless root

        ui.info Hirb::Helpers::ParentChildTree.render(root,
          :type => :directory,
          :value_method => display_value,
          :children_method => group_children)
      end

      def render_table
        ui.info Hirb::Helpers::AutoTable.render(context[:groups],
          :fields => fields,
          :headers => headers,
          :filters => filters,
          :max_fields => width_limits,
          :resize => false,
          :description => false)
      end
    end
  end
end
