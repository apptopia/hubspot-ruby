describe Hubspot::Deal do
  let(:example_deal_hash) do
    VCR.use_cassette("deal_example") do
      HTTParty.get("https://api.hubapi.com/deals/v1/deal/3?hapikey=demo&portalId=62515").parsed_response
    end
  end
  let(:logger) { mock('logger') }

  before{ Hubspot.configure(hapikey: "demo") }

  describe "#initialize" do
    subject{ Hubspot::Deal.new(example_deal_hash) }
    it  { should be_an_instance_of Hubspot::Deal }
    its (:portal_id) { should == 62515 }
    its (:deal_id) { should == 3 }
  end

  describe ".create!" do
    cassette "deal_create"
    let(:params) { {} }
    subject { Hubspot::Deal.create!(62515, [8954037], [27136], params) }
    its(:deal_id)     { should_not be_nil }
    its(:portal_id)   { should eql 62515 }
    its(:company_ids) { should eql [8954037]}
    its(:vids)        { should eql [27136]}

    context 'with logger' do
      let(:params){ {logger: logger} }
      it 'logs request' do
        mock(logger).log(:post, anything, anything, anything, anything){ true }
        subject
      end
    end
  end

  describe ".find" do
    cassette "deal_find"
    let(:deal) {Hubspot::Deal.create!(62515, [8954037], [27136], { amount: 30})}

    it 'must find by the deal id' do
      find_deal = Hubspot::Deal.find(deal.deal_id)
      find_deal.deal_id.should eql deal.deal_id
      find_deal.properties["amount"].should eql "30"
    end

    context 'with logger' do
      let(:params){ {logger: logger} }
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        Hubspot::Deal.find(deal.deal_id, logger: logger)
      end
    end
  end

  describe '.recent' do
    cassette 'find_all_recent_updated_deals'

    it 'must get the recents updated deals' do
      deals = Hubspot::Deal.recent

      first = deals.first
      last = deals.last

      expect(first).to be_a Hubspot::Deal
      expect(first.properties['amount']).to eql '0'
      expect(first.properties['dealname']).to eql '1420787916-gou2rzdgjzx2@u2rzdgjzx2.com'
      expect(first.properties['dealstage']).to eql 'closedwon'

      expect(last).to be_a Hubspot::Deal
      expect(last.properties['amount']).to eql '250'
      expect(last.properties['dealname']).to eql '1420511993-U9862RD9XR@U9862RD9XR.com'
      expect(last.properties['dealstage']).to eql 'closedwon'
    end

    it 'must filter only 2 deals' do
      deals = Hubspot::Deal.recent(count: 2)
      expect(deals.size).to eql 2
    end

    it 'it must offset the deals' do
      deal = Hubspot::Deal.recent(count: 1, offset: 1).first
      expect(deal.properties['dealname']).to eql '1420704406-goy6v83a97nr@y6v83a97nr.com'  # the third deal
    end

    context 'with logger' do
      let(:params){ {logger: logger} }
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        Hubspot::Deal.recent(logger: logger)
      end
    end
  end

  describe '#destroy!' do
    cassette 'destroy_deal'

    let(:deal) {Hubspot::Deal.create!(62515, [8954037], [27136], {amount: 30})}

    it 'should remove from hubspot' do
      expect(Hubspot::Deal.find(deal.deal_id)).to_not be_nil

      expect(deal.destroy!).to be_true
      expect(deal.destroyed?).to be_true

      expect{ Hubspot::Deal.find(deal.deal_id) }.to raise_error(Hubspot::RequestError)
    end

    context 'with logger' do
      let(:params){ {logger: logger} }
      it 'logs request' do
        mock(logger).log(:delete, anything, anything, anything, anything){ true }
        deal.destroy!(logger: logger)
      end
    end
  end

  describe '#update!' do
    cassette 'update_deal'

    let(:deal) {Hubspot::Deal.create!(62515, [8954037], [27136], {amount: 30})}
    let(:params) { {amount: 50} }
    subject { deal.update!(params) }

    it 'should update deal' do
      expect{ subject }.to change{ Hubspot::Deal.find(deal.deal_id).properties["amount"] }.from('30').to('50')
    end

    context 'with logger' do
      let(:params){ {amount: 50, logger: logger} }
      it 'logs request' do
        mock(logger).log(:put, anything, anything, anything, anything){ true }
        subject
      end
    end
  end

  describe '#[]' do
    subject{ Hubspot::Deal.new(example_deal_hash) }

    it 'should get a property' do
      subject.properties.each do |property, value|
        expect(subject[property]).to eql value
      end
    end
  end
end
