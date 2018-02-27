describe Hubspot::Company do
  let(:example_company_hash) do
    VCR.use_cassette("company_example", record: :none) do
      HTTParty.get("https://api.hubapi.com/companies/v2/companies/21827084?hapikey=demo").parsed_response
    end
  end
  let(:logger) { mock('logger') }

  before{ Hubspot.configure(hapikey: "demo") }

  describe "#initialize" do
    subject{ Hubspot::Company.new(example_company_hash) }
    it{ should be_an_instance_of Hubspot::Company }
    its(["name"]){ should == "HubSpot" }
    its(["domain"]){ should == "hubspot.com" }
    its(:vid){ should == 21827084 }
  end

  describe ".create!" do
    cassette "company_create"
    let(:params){{}}
    subject{ Hubspot::Company.create!(name, params) }
    context "with a new name" do
      let(:name){ "New Company #{Time.now.to_i}" }
      it{ should be_an_instance_of Hubspot::Company }
      its(:name){ should match /New Company .*/ } # Due to VCR the email may not match exactly

      context "and some params" do
        cassette "company_create_with_params"
        let(:name){ "New Company with Params #{Time.now.to_i}" }
        let(:params){ {domain: "new-company-domain-#{Time.now.to_i}"} }
        its(["name"]){ should match /New Company with Params/ }
        its(["domain"]){ should match /new\-company\-domain/ }
      end
    end

    context 'with logger' do
      let(:name){ "foo" }
      let(:params){ {logger: logger} }
      it 'logs request' do
        mock(logger).log(:post, anything, anything, anything, anything){ true }
        subject
      end
    end
  end

   describe ".find_by_id" do
    cassette "company_find_by_id"

    context 'given an uniq id' do
      subject{ Hubspot::Company.find_by_id(vid) }

      context "when the company is found" do
        let(:vid){ 21827084 }
        it{ should be_an_instance_of Hubspot::Company }
        its(:name){ should == "HubSpot" }

        context 'with logger' do
          it 'logs request' do
            mock(logger).log(:get, anything, anything, anything, anything){ true }
            described_class.find_by_id(vid, logger: logger)
          end
        end
      end

      context "when the contact cannot be found" do
        let(:vid){ 9999999 }

        it 'raises an error' do
          expect { subject }.to raise_error(Hubspot::RequestError)
        end

        context 'with logger' do
          it 'logs request' do
            mock(logger).log(:get, anything, anything, anything, anything){ true }
            expect { described_class.find_by_id(vid, logger: logger) }.to raise_error
          end
        end
      end
    end
  end

  describe ".find_by_domain" do
    cassette "company_find_by_domain"

    context 'given a domain' do
      subject{ Hubspot::Company.find_by_domain("hubspot.com") }

      context "when a company is found" do
        it{ should be_an_instance_of Array }
        it{ should_not be_empty }
      end

      context "when a company cannot be found" do
        subject{Hubspot::Company.find_by_domain("asdf1234baddomain.com")}
        it{ should be_an_instance_of Array }
        it{ should be_empty }
      end
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.find_by_domain("hubspot.com", logger: logger)
      end
    end
  end

  describe '.all' do
    cassette 'find_all_companies_paged'

    subject(:companies) { described_class.all(options) }

    context 'by default' do
      let(:options) { {} }

      it 'gets 100 companies' do
        expect(companies.size).to eq(100)
      end

      it 'returns companies only' do
        expect(companies.first).to be_a described_class
      end
    end

    context 'raw mode' do
      let(:options) { {raw: true} }

      it 'returns raw response' do
        expect(companies['has-more']).to eq(true)
      end
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.all(logger: logger)
      end
    end
  end

  describe '.recent' do
    context 'recent companies' do
      cassette 'find_all_companies'

      it 'must get the companies list' do
        companies = Hubspot::Company.recent

        expect(companies.size).to eql 20 # default page size

        first = companies.first
        last = companies.last

        expect(first).to be_a Hubspot::Company
        expect(first.vid).to eql 42866817
        expect(first['name']).to eql 'name'

        expect(last).to be_a Hubspot::Company
        expect(last.vid).to eql 42861017
        expect(first['name']).to eql 'name'
      end

      it 'must filter only 2 copmanies' do
        copmanies = Hubspot::Company.recent(count: 2)
        expect(copmanies.size).to eql 2
      end
    end

    context 'recently updated companies' do
      cassette 'find_all_recent_companies'

      it 'must get the companies list' do
        companies = Hubspot::Company.recent(recently_updated: true)
        expect(companies.size).to eql 20

        first, last = companies.first, companies.last
        expect(first).to be_a Hubspot::Company
        expect(first.vid).to eql 465714740

        expect(last).to be_a Hubspot::Company
        expect(last.vid).to eql 181368790
      end
    end

    context 'raw mode' do
      cassette 'find_all_companies'

      it 'returns raw response' do
        response = Hubspot::Company.recent(raw: true)
        expect(response['hasMore']).to eq(true)
      end
    end

    context 'with logger' do
      cassette 'find_all_companies'

      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.recent(logger: logger)
      end
    end
  end

  describe "#update!" do
    cassette "company_update"
    let(:company){ Hubspot::Company.new(example_company_hash) }
    let(:params){ {name: "Acme Cogs", domain: "abccogs.com"} }
    subject{ company.update!(params) }

    it{ should be_an_instance_of Hubspot::Company }
    its(["name"]){ should ==  "Acme Cogs" }
    its(["domain"]){ should ==  "abccogs.com" }

    context "when the request is not successful" do
      let(:company){ Hubspot::Company.new({"vid" => "invalid", "properties" => {}})}
      it "raises an error" do
        expect{ subject }.to raise_error Hubspot::RequestError
      end
    end

    context 'with logger' do
      let(:params){ {name: "Acme Cogs", domain: "abccogs.com", logger: logger} }

      it 'logs request' do
        mock(logger).log(:put, anything, anything, anything, anything){ true }
        subject
      end
    end
  end

  describe "#destroy!" do
    cassette "company_destroy"
    let(:company){ Hubspot::Company.create!("newcompany_y_#{Time.now.to_i}@hsgem.com") }
    subject{ company.destroy! }
    it { should be_true }
    it "should be destroyed" do
      subject
      company.destroyed?.should be_true
    end
    context "when the request is not successful" do
      let(:company){ Hubspot::Company.new({"vid" => "invalid", "properties" => {}})}
      it "raises an error" do
        expect{ subject }.to raise_error Hubspot::RequestError
        company.destroyed?.should be_false
      end
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:delete, anything, anything, anything, anything){ true }
        company.destroy!(logger: logger)
      end
    end
  end

  describe "#add_contact" do
    cassette "add_contact_to_company"
    let(:company){ Hubspot::Company.create!("company_#{Time.now.to_i}@example.com") }
    let(:contact){ Hubspot::Contact.create!("contact_#{Time.now.to_i}@example.com") }
    subject { Hubspot::Company.recent.last }
    context "with Hubspot::Contact instance" do
      before { company.add_contact contact }
      its(['num_associated_contacts']) { should eql '1' }
    end

    context "with vid" do
      before { company.add_contact contact.vid }
      its(['num_associated_contacts']) { should eql '1' }
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:put, anything, anything, anything, anything){ true }
        company.add_contact(contact.vid, logger: logger)
      end
    end
  end

  describe "#destroyed?" do
    let(:company){ Hubspot::Company.new(example_company_hash) }
    subject{ company }
    its(:destroyed?){ should be_false }
  end
end
