describe Hubspot::Topic do
  let(:logger) { mock('logger') }

  before do
    Hubspot.configure(hapikey: "demo")
  end

  describe ".list" do
    cassette "topics_list"
    let(:topics) { Hubspot::Topic.list }

    it "should have a list of topics" do
      topics.count.should be(3)
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        Hubspot::Topic.list(logger: logger)
      end
    end
  end

  describe ".find_by_topic_id" do
    cassette "topics_list"
    let(:topic_id) { 349001328 }

    it "should find a specific topic" do
      topic = Hubspot::Topic.find_by_topic_id(topic_id)
      topic['id'].should eq(topic_id)
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        Hubspot::Topic.find_by_topic_id(topic_id, logger: logger)
      end
    end
  end
end

