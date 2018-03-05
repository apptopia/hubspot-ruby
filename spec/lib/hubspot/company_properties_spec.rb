describe Hubspot::CompanyProperties do
  let(:logger) { mock('logger') }

  before{ Hubspot.configure(hapikey: "demo") }

  describe '.all' do
    cassette 'company_property_all'
    subject(:properties){ described_class.all }

    it 'gets all companies properties' do
      expect(properties.size).to eq(921)
    end

    it 'returns company properties only' do
      expect(properties.first).to be_a described_class
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.all(logger: logger)
      end
    end
  end

  describe '.find_by_name' do
    cassette 'company_property_find_by_name'
    let(:name) { 'about_us' }
    subject(:property) { described_class.find_by_name(name) }

    it{ should be_an_instance_of described_class }
    its(:properties) { should include('label' => 'About Us') }

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.find_by_name(name, logger: logger)
      end
    end
  end

  describe '.create!' do
    cassette 'company_property_create'
    let(:group_name) { 'companyinformation' }
    let(:name) { 'foo_test_property' }
    let(:params) { {name: name, label: 'Foo Test Property', type: 'string'} }
    subject{ described_class.create!(group_name, params) }

    it{ should be_an_instance_of described_class }
    its(:name){ should eq(name) }

    context 'with logger' do
      let(:params) { {name: name, label: 'Foo Test Property', type: 'string', logger: logger} }
      it 'logs request' do
        mock(logger).log(:post, anything, anything, anything, anything){ true }
        subject
      end
    end
  end

  describe '.update!' do
    cassette 'company_property_update'
    let(:new_label) { 'Bar Test Property' }
    subject{ described_class.update!(name, params) }

    context 'for existed property' do
      let(:name) { 'foo_test_property' }
      let(:params) { {type: 'string', groupName: 'companyinformation', label: new_label} }
      its(:properties){ should include('label' => new_label) }
    end

    context 'for non existed property' do
      let(:name) { 'bar_test_property' }
      let(:params) { {type: 'string', groupName: 'companyinformation', label: new_label} }
      its(:properties){ should include('label' => new_label) }
    end

    context 'with logger' do
      let(:name) { 'foo_test_property' }
      let(:params) { {type: 'string', groupName: 'companyinformation', label: new_label, logger: logger} }
      it 'logs request' do
        mock(logger).log(:put, anything, anything, anything, anything){ true }
        subject
      end
    end
  end
end
