module Hubspot
  #
  # HubSpot Contacts API
  #
  # {https://developers.hubspot.com/docs/methods/contacts/contacts-overview}
  #
  # TODO: work on all endpoints that can specify contact properties, property mode etc... as params. cf pending specs
  class Contact
    CREATE_CONTACT_PATH          = "/contacts/v1/contact"
    GET_CONTACT_BY_EMAIL_PATH    = "/contacts/v1/contact/email/:contact_email/profile"
    GET_CONTACTS_BY_EMAIL_PATH   = "/contacts/v1/contact/emails/batch"
    GET_CONTACT_BY_ID_PATH       = "/contacts/v1/contact/vid/:contact_id/profile"
    CONTACT_BATCH_PATH           = '/contacts/v1/contact/vids/batch'
    GET_CONTACT_BY_UTK_PATH      = "/contacts/v1/contact/utk/:contact_utk/profile"
    GET_CONTACTS_BY_UTK_PATH     = '/contacts/v1/contact/utks/batch'
    UPDATE_CONTACT_PATH          = "/contacts/v1/contact/vid/:contact_id/profile"
    DESTROY_CONTACT_PATH         = "/contacts/v1/contact/vid/:contact_id"
    CONTACTS_PATH                = "/contacts/v1/lists/all/contacts/all"
    RECENT_CONTACTS_PATH         = '/contacts/v1/lists/recently_updated/contacts/recent'
    BATCH_CREATE_OR_UPDATE_PATH  = '/contacts/v1/contact/batch/'
    CREATE_OR_UPDATE_PATH        = '/contacts/v1/contact/createOrUpdate/email/:contact_email'

    class << self
      # {https://developers.hubspot.com/docs/methods/contacts/create_contact}
      def create!(email, params={})
        logger = params.delete(:logger) { false }
        params_with_email = params.stringify_keys.merge("email" => email)
        post_data = {properties: Hubspot::Utils.hash_to_properties(params_with_email)}
        response = Hubspot::Connection.post_json(CREATE_CONTACT_PATH,
                                                 params: {},
                                                 body: post_data,
                                                 logger: logger)
        new(response)
      end

      # {https://developers.hubspot.com/docs/methods/contacts/get_contacts}
      # {https://developers.hubspot.com/docs/methods/contacts/get_recently_updated_contacts}
      def all(opts={})
        raw = opts.delete(:raw) { false }
        recent = opts.delete(:recent) { false }
        path, opts =
        if recent
          [RECENT_CONTACTS_PATH, Hubspot::ContactProperties.add_default_parameters(opts)]
        else
          [CONTACTS_PATH, opts]
        end

        response = Hubspot::Connection.get_json(path, opts)
        raw ? response : response['contacts'].map { |c| new(c) }
      end

      # TODO: Add non-batch support: {https://developers.hubspot.com/docs/methods/contacts/create_or_update}
      # NOTE: Performance is best when calls are limited to 100 or fewer contacts
      # {https://developers.hubspot.com/docs/methods/contacts/batch_create_or_update}
      def create_or_update!(contacts, opts={})
        logger = opts.delete(:logger) { false }
        query = contacts.map do |ch|
          contact_hash = ch.with_indifferent_access
          contact_param = {
            properties: Hubspot::Utils.hash_to_properties(contact_hash.except(:vid))
          }
          if contact_hash[:vid]
            contact_param.merge!(vid: contact_hash[:vid])
          elsif contact_hash[:email]
            contact_param.merge!(email: contact_hash[:email])
          else
            raise Hubspot::InvalidParams, 'expecting vid or email for contact'
          end
          contact_param
        end
        Hubspot::Connection.post_json(BATCH_CREATE_OR_UPDATE_PATH,
                                      params: {},
                                      body: query,
                                      logger: logger)
      end

      # {http://developers.hubspot.com/docs/methods/contacts/create_or_update}
      def create_or_update_by_email!(email, params={})
        logger = params.delete(:logger) { false }
        params_with_email = params.stringify_keys
        params_with_email["email"] ||= email
        post_data = {properties: Hubspot::Utils.hash_to_properties(params_with_email)}

        Hubspot::Connection.post_json(CREATE_OR_UPDATE_PATH,
                                      params: {contact_email: email}.stringify_keys,
                                      body: post_data,
                                      logger: logger)
      end

      # NOTE: problem with batch api endpoint
      # {https://developers.hubspot.com/docs/methods/contacts/get_contact}
      # {https://developers.hubspot.com/docs/methods/contacts/get_batch_by_vid}
      def find_by_id(vids, opts={})
        logger = opts.delete(:logger) { false }
        raw = opts.delete(:raw) { false } 
        batch_mode, path, params = case vids
        when Integer then [false, GET_CONTACT_BY_ID_PATH, { contact_id: vids, logger: logger }]
        when Array then [true, CONTACT_BATCH_PATH, { batch_vid: vids, logger: logger }]
        else raise Hubspot::InvalidParams, 'expecting Integer or Array of Integers parameter'
        end

        response = Hubspot::Connection.get_json(path, params)
        raise Hubspot::ApiError if batch_mode
        raw ? response : new(response)
      end

      # {https://developers.hubspot.com/docs/methods/contacts/get_contact_by_email}
      # {https://developers.hubspot.com/docs/methods/contacts/get_batch_by_email}
      def find_by_email(emails, opts={})
        logger = opts.delete(:logger) { false }
        batch_mode, path, params = case emails
        when String then [false, GET_CONTACT_BY_EMAIL_PATH, { contact_email: emails, logger: logger }]
        when Array then [true, GET_CONTACTS_BY_EMAIL_PATH, { batch_email: emails, logger: logger }]
        else raise Hubspot::InvalidParams, 'expecting String or Array of Strings parameter'
        end

        response = Hubspot::Connection.get_json(path, params)
        if batch_mode
          response.map { |_vid, contact| new(contact) }
        else
          new(response)
        end
      end

      # NOTE: problem with batch api endpoint
      # {https://developers.hubspot.com/docs/methods/contacts/get_contact_by_utk}
      # {https://developers.hubspot.com/docs/methods/contacts/get_batch_by_utk} 
      def find_by_utk(utks, opts={})
        logger = opts.delete(:logger) { false }
        batch_mode, path, params = case utks
        when String then [false, GET_CONTACT_BY_UTK_PATH, { contact_utk: utks, logger: logger }]
        when Array then [true, GET_CONTACTS_BY_UTK_PATH, { batch_utk: utks, logger: logger }]
        else raise Hubspot::InvalidParams, 'expecting String or Array of Strings parameter'
        end

        response = Hubspot::Connection.get_json(path, params)
        raise Hubspot::ApiError if batch_mode
        new(response)
      end

      # {https://developers.hubspot.com/docs/methods/contacts/search_contacts}
      def search(query, count=100)
        raise NotImplementedError
      end
    end

    attr_reader :properties
    attr_reader :vid

    def initialize(response_hash)
      @properties = Hubspot::Utils.properties_to_hash(response_hash["properties"])
      @vid = response_hash["vid"]
    end

    def [](property)
      @properties[property]
    end

    def email
      @properties["email"]
    end

    def utk
      @properties["usertoken"]
    end

    # Updates the properties of a contact
    # {https://developers.hubspot.com/docs/methods/contacts/update_contact}
    # @param params [Hash] hash of properties to update
    # @return [Hubspot::Contact] self
    def update!(params)
      logger = params.delete(:logger) { false }
      query = {"properties" => Hubspot::Utils.hash_to_properties(params.stringify_keys!)}
      response = Hubspot::Connection.post_json(UPDATE_CONTACT_PATH,
                                               params: {contact_id: vid},
                                               body: query,
                                               logger: logger)
      @properties.merge!(params)
      self
    end

    # Archives the contact in hubspot
    # {https://developers.hubspot.com/docs/methods/contacts/delete_contact}
    # @return [TrueClass] true
    def destroy!(opts={})
      logger = opts.delete(:logger) { false }
      response = Hubspot::Connection.delete_json(DESTROY_CONTACT_PATH,
                                                 contact_id: vid,
                                                 logger: logger)
      @destroyed = true
    end

    def destroyed?
      !!@destroyed
    end
  end
end
