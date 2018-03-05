module Hubspot
  class CompanyProperties
    PROPERTY_PATH = '/companies/v2/properties/'
    PROPERTY_PATH_BY_NAME = '/companies/v2/properties/named/'
    class << self
      # {http://developers.hubspot.com/docs/methods/companies/get_company_properties}
      def all(params = {})
        response = Hubspot::Connection.get_json(PROPERTY_PATH, params)
        response.map{|property| new(property)}
      end

      # {http://developers.hubspot.com/docs/methods/companies/get_company_property}
      def find_by_name(name, params = {})
        response = Hubspot::Connection.get_json("#{PROPERTY_PATH_BY_NAME}#{name}", params)
        new(response)
      end

      # {http://developers.hubspot.com/docs/methods/companies/create_company_property}
      def create!(group_name, params = {})
        logger = params.delete(:logger) { false }
        params = params.merge(format_group_name(group_name))
        response = Hubspot::Connection.post_json(PROPERTY_PATH, params: {}, body: params.stringify_keys, logger: logger)
        new(response)
      end

      # {http://developers.hubspot.com/docs/methods/companies/update_company_property}
      def update!(name, params = {})
        logger = params.delete(:logger) { false }
        params = params.merge(format_group_name(params[:groupName]))
        response = Hubspot::Connection.put_json("#{PROPERTY_PATH_BY_NAME}#{name}", params: {}, body: params.stringify_keys, logger: logger)
        new(response)
      end

      def create_or_update!(group_name, name, params = {})
        update!(name, params.merge(groupName: group_name))
      rescue Hubspot::RequestError
        create!(group_name, params.merge(name: name))
      end

      # {http://developers.hubspot.com/docs/methods/companies/delete_company_property}
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
