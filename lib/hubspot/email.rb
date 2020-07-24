module Hubspot
  #
  # HubSpot Email API
  #
  # {https://legacydocs.hubspot.com/docs/methods/email/transactional_email}
  #
  class Email
    SINGLE_SEND_EMAIL_PATH = '/email/public/v1/singleEmail/send'.freeze

    def self.send_email(email_id, message_props, custom_props = {}, contact_props = {})
      custom_params = Hubspot::Utils.hash_to_properties(custom_props, key_name: "name")
      contact_params = Hubspot::Utils.hash_to_properties(contact_props, key_name: "name")
      Hubspot::Connection.post_json(
        SINGLE_SEND_EMAIL_PATH,
        params: {},
        body: {
          emailId: email_id,
          message: message_props,
          contactProperties: contact_params,
          customProperties: custom_params
        }
      )
    end
  end
end
