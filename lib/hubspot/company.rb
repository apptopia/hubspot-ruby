module Hubspot
  #
  # HubSpot Companies API
  #
  # {http://developers.hubspot.com/docs/methods/companies/companies-overview}
  #
  class Company
    CREATE_COMPANY_PATH               = "/companies/v2/companies/"
    ALL_COMPANIES_PATH                = "/companies/v2/companies/paged"
    RECENTLY_CREATED_COMPANIES_PATH   = "/companies/v2/companies/recent/created"
    RECENTLY_MODIFIED_COMPANIES_PATH  = "/companies/v2/companies/recent/modified"
    GET_COMPANY_BY_ID_PATH            = "/companies/v2/companies/:company_id"
    GET_COMPANY_BY_DOMAIN_PATH        = "/companies/v2/companies/domain/:domain"
    UPDATE_COMPANY_PATH               = "/companies/v2/companies/:company_id"
    ADD_CONTACT_TO_COMPANY_PATH       = "/companies/v2/companies/:company_id/contacts/:vid"
    DESTROY_COMPANY_PATH              = "/companies/v2/companies/:company_id"

    class << self
      # Find all companies
      # @param opts [Hash] Possible options are:
      #    raw [Boolean] returns rfaw response instead of companies list
      #    count [Integer] for pagination
      #    offset [Integer] for pagination
      # {https://developers.hubspot.com/docs/methods/companies/get-all-companies}
      # @return [Array] Array of Hubspot::Company records
      def all(opts={})
        raw = opts.delete(:raw) { false } 
        response = Hubspot::Connection.get_json(ALL_COMPANIES_PATH, opts)
        raw ? response : response['companies'].map { |c| new(c) }
      end

      # Find recent companies by created date (descending)
      # @param opts [Hash] Possible options are:
      #    recently_updated [boolean] (for querying all accounts by modified time)
      #    count [Integer] for pagination
      #    offset [Integer] for pagination
      # {http://developers.hubspot.com/docs/methods/companies/get_companies_created}
      # {http://developers.hubspot.com/docs/methods/companies/get_companies_modified}
      # @return [Array] Array of Hubspot::Company records
      def recent(opts={})
        raw = opts.delete(:raw) { false } 
        recently_updated = opts.delete(:recently_updated) { false }
        path = if recently_updated
          RECENTLY_MODIFIED_COMPANIES_PATH
        else
          RECENTLY_CREATED_COMPANIES_PATH
        end

        response = Hubspot::Connection.get_json(path, opts)

        raw ? response : response['results'].map { |c| new(c) }
      end

      # Finds a list of companies by domain
      # {http://developers.hubspot.com/docs/methods/companies/get_companies_by_domain}
      # @param domain [String] company domain to search by
      # @return [Array] Array of Hubspot::Company records
      def find_by_domain(domain, opts={})
        path = GET_COMPANY_BY_DOMAIN_PATH
        params = opts.merge(domain: domain)
        raise Hubspot::InvalidParams, 'expecting Integer parameter' unless domain.try(:is_a?, String)

        companies = []
        begin
          response = Hubspot::Connection.get_json(path, params)
          companies = response.try(:map) { |company| new(company) }
        rescue => e
          raise e unless e.message =~ /not found/ # 404 / hanle the error and kindly return an empty array
        end
        companies
      end

      # Finds a company by domain
      # {http://developers.hubspot.com/docs/methods/companies/get_company}
      # @param id [Integer] company id to search by
      # @return [Hubspot::Company] Company record
      def find_by_id(id, opts={})
        raw = opts.delete(:raw) { false }
        path = GET_COMPANY_BY_ID_PATH
        params = opts.merge(company_id: id)
        raise Hubspot::InvalidParams, 'expecting Integer parameter' unless id.try(:is_a?, Integer)
        response = Hubspot::Connection.get_json(path, params)
        raw ? response : new(response)
      end

      # Creates a company with a name
      # {http://developers.hubspot.com/docs/methods/companies/create_company}
      # @param name [String]
      # @return [Hubspot::Company] Company record
      def create!(name, params={})
        logger = params.delete(:logger) { false }
        params_with_name = params.stringify_keys.merge("name" => name)
        post_data = {properties: Hubspot::Utils.hash_to_properties(params_with_name, key_name: "name")}
        response = Hubspot::Connection.post_json(CREATE_COMPANY_PATH, params: {}, body: post_data, logger: logger)
        new(response)
      end
    end

    attr_reader :properties
    attr_reader :vid, :name

    def initialize(response_hash)
      @properties = Hubspot::Utils.properties_to_hash(response_hash["properties"])
      @vid = response_hash["companyId"]
      @name = @properties.try(:[], "name")
    end

    def [](property)
      @properties[property]
    end

    # Updates the properties of a company
    # {http://developers.hubspot.com/docs/methods/companies/update_company}
    # @param params [Hash] hash of properties to update
    # @return [Hubspot::Company] self
    def update!(params)
      logger = params.delete(:logger) { false }
      query = {"properties" => Hubspot::Utils.hash_to_properties(params.stringify_keys!, key_name: "name")}
      response = Hubspot::Connection.put_json(UPDATE_COMPANY_PATH, params: { company_id: vid }, body: query, logger: logger)
      @properties.merge!(params)
      self
    end

    # Adds contact to a company
    # {http://developers.hubspot.com/docs/methods/companies/add_contact_to_company}
    # @param id [Integer] contact id to add
    # @return [Hubspot::Company] self
    def add_contact(contact_or_vid, opts={})
      logger = opts.delete(:logger) { false }
      contact_vid = if contact_or_vid.is_a?(Hubspot::Contact)
                      contact_or_vid.vid
                    else
                      contact_or_vid
                    end
      Hubspot::Connection.put_json(ADD_CONTACT_TO_COMPANY_PATH,
                                   params: {
                                     company_id: vid,
                                     vid: contact_vid,
                                   },
                                   body: nil,
                                   logger: logger)
      self
    end

    # Archives the company in hubspot
    # {http://developers.hubspot.com/docs/methods/companies/delete_company}
    # @return [TrueClass] true
    def destroy!(opts={})
      logger = opts.delete(:logger) { false }
      response = Hubspot::Connection.delete_json(DESTROY_COMPANY_PATH, company_id: vid, logger: logger)
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end

  end
end
