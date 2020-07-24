module Hubspot
  #
  # HubSpot Email API
  #
  # {https://legacydocs.hubspot.com/docs/methods/email/transactional_email}
  #
  class Email
    SINGLE_SEND_EMAIL_PATH = '/email/public/v1/singleEmail/send'.freeze

    attr_reader :email_id

    def initialize(email_id)
      @email_id = email_id
    end

    def send_email(message_props, custom_params = {}, contact_params = {})
      Hubspot::Connection.post_json(
        SINGLE_SEND_EMAIL_PATH,
        params: {},
        body: {
          emailId: email_id,
          message: message_props,
          contactProperties: params_to_props(contact_params),
          customProperties: params_to_props(custom_params)
        }
      )
    end

    private

    def params_to_props(params)
      Hubspot::Utils.hash_to_properties(params, key_name: 'name')
    end
  end
end
