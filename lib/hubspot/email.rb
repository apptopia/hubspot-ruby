module Hubspot
  #
  # HubSpot Email API
  #
  # {https://legacydocs.hubspot.com/docs/methods/email/transactional_email}
  #
  class Email
    SINGLE_SEND_EMAIL_PATH = '/email/public/v1/singleEmail/send'.freeze

    def self.send_email(email_id, message_props, message_json_body = {})
      post_params = Hubspot::Utils.hash_to_properties(message_json_body, key_name: "name")
      Hubspot::Connection.post_json(
        SINGLE_SEND_EMAIL_PATH,
        params: {},
        body: {
          emailId: email_id,
          message: message_props,
        }.merge(post_params)
      )
    end
  end
end
