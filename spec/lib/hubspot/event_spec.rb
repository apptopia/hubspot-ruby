describe Hubspot::Event do
  let(:logger) { mock('logger') }
  let(:event_id) { '000000001625' }
  let(:email) { 'testingapis@hubspot.com' }

  before{ Hubspot.configure(portal_id: "62515", hapikey: 'demo') }

  describe '.track' do
    cassette "event_track"

    context 'with_logger' do
      let(:params) { {email: email, logger: logger} }

      it 'logs request' do
        mock(logger).log(:get, "http://track.hubspot.com#{described_class::TRACK_EVENT_URL}?email=testingapis%40hubspot.com&_n=#{event_id}&_a=62515", anything, anything, anything){ true }
        described_class.track(event_id, params)
      end
    end
  end

  describe '.track_and_set_properties' do
    cassette "event_track_and_set_properties"

    context 'with_logger' do
      let(:contact_properties) { {email: email, logger: logger} }

      it 'logs two requests' do
        mock(Hubspot::Contact).create_or_update_by_email!(email, contact_properties){ true }
        mock(described_class).track(event_id, {logger: logger}){ true }
        described_class.track_and_set_properties(event_id, email, contact_properties)
      end
    end
  end
end