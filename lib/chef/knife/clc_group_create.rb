require 'chef/knife/clc_base'

class Chef
  class Knife
    class ClcGroupCreate < Knife
      include Knife::ClcBase

      banner 'knife clc group create (options)'

      option :clc_name,
        :long => '--name NAME',
        :description => 'Name of the group to create',
        :on => :head

      option :clc_description,
        :long => '--description DESCRIPTION',
        :description => 'User-defined description of this group',
        :on => :head

      option :clc_parent,
        :long => '--parent ID',
        :description => "ID of the parent group. Retrieved from query to parent group, or by looking at the URL on the UI pages in the Control Portal",
        :on => :head

      option :clc_custom_fields,
        :long => '--custom-field KEY=VALUE',
        :description => 'Custom field key-value pair',
        :on => :head,
        :proc => ->(param) do
          Chef::Config[:knife][:clc_custom_fields] ||= []
          Chef::Config[:knife][:clc_custom_fields] << param
        end

      def parse_and_validate_parameters
        unless config[:clc_name]
          errors << 'Name is required'
        end

        unless config[:clc_parent]
          errors << 'Parent Group ID is required'
        end

        custom_fields = config[:clc_custom_fields]
        if custom_fields && custom_fields.any?
          parse_custom_fields(custom_fields)
        end
      end

      def parse_custom_fields(custom_fields)
        custom_fields.map! do |param|
          key, value = param.split('=', 2)

          unless key && value
            errors << "Custom field definition #{param} is malformed"
            next
          end

          { 'id' => key, 'value' => value }
        end
      end

      def prepare_group_params
        {
          'name' => config[:clc_name],
          'description' => config[:clc_description],
          'parentGroupId' => config[:clc_parent],
          'customFields' => config[:clc_custom_fields]
        }.delete_if { |_, value| value.nil? || value.empty? }
      end

      def execute
        group = connection.create_group(prepare_group_params)
        parent_link = group['links'].detect { |link| link['rel'] == 'parentGroup' }
        group['parent'] = parent_link['id']

        context[:group] = group

        render
      end

      def fields
        %w(name id locationId description type status parent)
      end

      def headers
        {
          'name' => 'Name',
          'id' => 'ID',
          'locationId' => 'Location',
          'description' => 'Description',
          'type' => 'Type',
          'status' => 'Status',
          'parent' => 'Parent'
        }
      end

      def render
        group = context[:group]

        fields.each do |field|
          header = headers.fetch(field, field.capitalize)
          value = group.fetch(field, '-')

          if value
            ui.info ui.color(header, :bold) + ': ' + value.to_s
          end
        end
      end
    end
  end
end
