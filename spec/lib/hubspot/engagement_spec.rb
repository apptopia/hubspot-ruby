describe Hubspot::Engagement do
  let(:example_engagement_hash) do
    VCR.use_cassette("engagement_example", record: :once) do
      HTTParty.get("https://api.hubapi.com/engagements/v1/engagements/4318933?hapikey=demo").parsed_response
    end
  end

  before{ Hubspot.configure(hapikey: "demo") }

  describe "#initialize" do
    subject{ Hubspot::Engagement.new(example_engagement_hash) }
    it{ should be_an_instance_of Hubspot::Engagement }
    its(:id){ should eq(4318933) }
    its(:portal_id){ should eq(62515) }
    its(:active){ should eq(true) }
    its(:created_at){ should eq(Time.parse('2015-04-09 16:37:00')) }
    its(:last_updated){ should eq(Time.parse('2016-11-22 17:17:31')) }
    its(:created_by){ should eq(215482) }
    its(:modified_by){ should eq(215482) }
    its(:owner_id){ should eq(70) }
    its(:type){ should eq('NOTE') }
    its(:timestamp){ should eq(Time.parse('2015-04-09 16:37:00')) }
  end

  describe '.all' do
    cassette 'find_all_engagements_paged'

    subject(:engagements) { described_class.all(options) }

    context 'by default' do
      let(:options) { {} }

      it 'gets 100 engagements' do
        expect(engagements.size).to eq(100)
      end

      it 'returns engagements only' do
        expect(engagements.first).to be_a Hubspot::Engagement
      end
    end

    context 'raw mode' do
      let(:options) { {raw: true} }

      it 'returns raw response' do
        expect(engagements['hasMore']).to eq(true)
      end
    end
  end

  describe '.recent' do
    cassette 'find_recent_engagements_paged'

    subject(:engagements) { described_class.recent(options) }

    context 'by default' do
      let(:options) { {} }

      it 'gets 20 engagements' do
        expect(engagements.size).to eq(20)
      end

      it 'returns engagements only' do
        expect(engagements.first).to be_a Hubspot::Engagement
      end
    end

    context 'raw mode' do
      let(:options) { {raw: true} }

      it 'returns raw response' do
        expect(engagements['hasMore']).to eq(true)
      end
    end
  end
end
