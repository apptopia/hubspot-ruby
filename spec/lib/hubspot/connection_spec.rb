require 'timecop'

describe Hubspot::Connection do
  let(:params) { {} }
  let(:url) { 'http://localhost:3000' }
  let(:http_reponse) { mock('http_response') }
  let(:logger) { mock('logger') }
  before(:each) do
    http_reponse.success?.any_times { true }
    http_reponse.parsed_response.any_times { {} }
  end

  describe '.get_json' do
    before do
      mock(Hubspot::Connection).generate_url(url, params) { url }
      mock(Hubspot::Connection).get(url, format: :json) { http_reponse }
    end

    it 'delegates url format to Hubspot::Utils, call HTTParty get and returns response' do
      Hubspot::Connection.get_json(url, params)
    end

    context 'if logger provided' do
      let(:params) { {foo: :bar, logger: logger} }

      it 'logs requests' do
        Timecop.freeze do
          mock(logger).log(:get, url, {foo: :bar}, true, 0){ true }
          Hubspot::Connection.get_json(url, params)
        end
      end
    end
  end

  describe '.post_json' do
    before do
      mock(Hubspot::Connection).generate_url(url, params) { url }
      mock(Hubspot::Connection).post(url, body: "{}", headers: {"Content-Type"=>"application/json"}, format: :json) { http_reponse }
    end

    it 'delegates url format to Hubspot::Utils, call HTTParty post and returns response' do
      Hubspot::Connection.post_json(url, params: params, body: {})
    end

    context 'if logger provided' do
      let(:params) { {foo: :bar} }

      it 'logs requests' do
        Timecop.freeze do
          mock(logger).log(:post, url, {:params=>{:foo=>:bar}, :body=>{}}, true, 0){ true }
          Hubspot::Connection.post_json(url, params: params, body: {}, logger: logger)
        end
      end
    end
  end

  describe '.put_json' do
    before do
      mock(Hubspot::Connection).generate_url(url, params) { url }
      mock(Hubspot::Connection).put(url, body: "{}", headers: {"Content-Type"=>"application/json"}, format: :json) { http_reponse }
    end

    it 'delegates url format to Hubspot::Utils, call HTTParty put and returns response' do
      Hubspot::Connection.put_json(url, params: params, body: {})
    end

    context 'if logger provided' do
      let(:params) { {foo: :bar} }

      it 'logs requests' do
        Timecop.freeze do
          mock(logger).log(:put, url, {:params=>{:foo=>:bar}, :body=>{}}, true, 0){ true }
          Hubspot::Connection.put_json(url, params: params, body: {}, logger: logger)
        end
      end
    end
  end

  describe '.delete_json' do
    before do
      mock(Hubspot::Connection).generate_url(url, params) { url }
      mock(Hubspot::Connection).delete(url, format: :json) { http_reponse }
    end

    it 'delegates url format to Hubspot::Utils, call HTTParty delete and returns response' do
      Hubspot::Connection.delete_json(url, params)
    end

    context 'if logger provided' do
      let(:params) { {foo: :bar, logger: logger} }

      it 'logs requests' do
        Timecop.freeze do
          mock(logger).log(:delete, url, {foo: :bar}, true, 0){ true }
          Hubspot::Connection.delete_json(url, params)
        end
      end
    end
  end

  context 'private methods' do
    describe ".generate_url" do
      let(:path){ "/test/:email/profile" }
      let(:params){{email: "test"}}
      let(:options){{}}
      subject{ Hubspot::Connection.send(:generate_url, path, params, options) }
      before{ Hubspot.configure(hapikey: "demo", portal_id: "62515") }

      it "doesn't modify params" do
        expect{ subject }.to_not change{params}
      end

      context "with a portal_id param" do
        let(:path){ "/test/:portal_id/profile" }
        let(:params){{}}
        it{ should == "https://api.hubapi.com/test/62515/profile?hapikey=demo" }
      end

      context "when configure hasn't been called" do
        before{ Hubspot::Config.reset! }
        it "raises a config exception" do
          expect{ subject }.to raise_error Hubspot::ConfigurationError
        end
      end

      context "with interpolations but no params" do
        let(:params){{}}
        it "raises an interpolation exception" do
          expect{ subject }.to raise_error Hubspot::MissingInterpolation
        end
      end

      context "with an interpolated param" do
        let(:params){ {email: "email@address.com"} }
        it{ should == "https://api.hubapi.com/test/email%40address.com/profile?hapikey=demo" }
      end

      context "with multiple interpolated params" do
        let(:path){ "/test/:email/:id/profile" }
        let(:params){{email: "email@address.com", id: 1234}}
        it{ should == "https://api.hubapi.com/test/email%40address.com/1234/profile?hapikey=demo" }
      end

      context "with query params" do
        let(:params){{email: "email@address.com", id: 1234}}
        it{ should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&hapikey=demo" }

        context "containing a time" do
          let(:start_time) { Time.now }
          let(:params){{email: "email@address.com", id: 1234, start: start_time}}
          it{ should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&start=#{start_time.to_i * 1000}&hapikey=demo" }
        end

        context "containing a range" do
          let(:start_time) { Time.now }
          let(:end_time) { Time.now + 1.year }
          let(:params){{email: "email@address.com", id: 1234, created__range: start_time..end_time }}
          it{ should == "https://api.hubapi.com/test/email%40address.com/profile?id=1234&created__range=#{start_time.to_i * 1000}&created__range=#{end_time.to_i * 1000}&hapikey=demo" }
        end

        context "containing an array of strings" do
          let(:path){ "/test/emails" }
          let(:params){{batch_email: %w(email1@example.com email2@example.com)}}
          it{ should == "https://api.hubapi.com/test/emails?email=email1%40example.com&email=email2%40example.com&hapikey=demo" }
        end
      end

      context "with options" do
        let(:options){ {base_url: "https://cool.com", hapikey: false} }
        it{ should == "https://cool.com/test/test/profile"}
      end

      context "passing Array as parameters for batch mode, key is prefixed with batch_" do
        let(:path) { Hubspot::ContactList::LIST_BATCH_PATH }
        let(:params) { { batch_list_id: [1,2,3] } }
        it{ should == "https://api.hubapi.com/contacts/v1/lists/batch?listId=1&listId=2&listId=3&hapikey=demo" }
      end
    end
  end
end
