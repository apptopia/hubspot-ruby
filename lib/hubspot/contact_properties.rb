module Hubspot
  class ContactProperties
    PROPERTY_PATH = '/contacts/v2/properties/'
    PROPERTY_PATH_BY_NAME = '/contacts/v2/properties/named/'
    class << self
      # TODO: properties can be set as configuration
      # TODO: find the way how to set a list of Properties + merge same property key if present from opts
      def add_default_parameters(opts={})
        properties = 'email'
        opts.merge(property: properties)
      end

      # {http://developers.hubspot.com/docs/methods/contacts/v2/get_contacts_properties}
      def all
        response = Hubspot::Connection.get_json(PROPERTY_PATH, {})
        response.map{|property| new(property)}
      end

      # {http://developers.hubspot.com/docs/methods/companies/get_contact_property}
      def find_by_name(name)
        response = Hubspot::Connection.get_json("#{PROPERTY_PATH_BY_NAME}#{name}", {})
        new(response)
      end

      # {http://developers.hubspot.com/docs/methods/contacts/v2/create_contacts_property}
      def create!(group_name, params = {})
        params = params.merge(format_group_name(group_name))
        response = Hubspot::Connection.post_json(PROPERTY_PATH, params: {}, body: params.stringify_keys)
        new(response)
      end

      # {http://developers.hubspot.com/docs/methods/contacts/v2/update_contact_property}
      def update!(name, params = {})
        params = params.merge(format_group_name(params[:groupName]))
        response = Hubspot::Connection.put_json("#{PROPERTY_PATH_BY_NAME}#{name}", params: {}, body: params.stringify_keys)
        new(response)
      end

      # {http://developers.hubspot.com/docs/methods/contacts/v2/delete_contact_property}
      def delete(name)
        response = Hubspot::Connection.delete_json("#{PROPERTY_PATH_BY_NAME}#{name}", {})
        response.success?
      end

      protected

      def format_group_name(group_name)
        {groupName: group_name.downcase.gsub(/ /, '_')}
      end
    end

    attr_reader :name
    attr_reader :properties

    def initialize(response_hash)
      @properties = response_hash
      @name = response_hash["name"]
    end

    def [](property)
      @properties[property]
    end
  end
end
