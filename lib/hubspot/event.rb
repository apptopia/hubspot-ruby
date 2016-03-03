module Hubspot
  class Event
    TRACK_EVENT_URL = '/v1/event/'
    class << self
      # {http://developers.hubspot.com/docs/methods/enterprise_events/http_api}
      def track(event_id, options = {})
        params = options.merge(_n: event_id.to_s).stringify_keys
        Hubspot::Connection.track(TRACK_EVENT_URL, params)
      end
    end
  end
end
