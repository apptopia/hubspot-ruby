module Hubspot
  class Event
    TRACK_EVENT_URL = '/v1/event/'
    class << self
      # {http://developers.hubspot.com/docs/methods/enterprise_events/http_api}
      def track(event_id, options = {})
        params = options.merge(_n: event_id.to_s).stringify_keys
        Hubspot::Connection.track(TRACK_EVENT_URL, params)
      end

      def track_and_set_properties(event_id, contact_email, contact_properties)
        Hubspot::Contact.create_or_update_by_email!(contact_email, contact_properties)
        track(event_id)
      end
    end
  end
end
