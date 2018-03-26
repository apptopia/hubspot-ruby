describe Hubspot::ContactProperties do
  before{ Hubspot.configure(hapikey: "demo") }
  let(:logger) { mock('logger') }
  let(:current_properties_amount) { 1002 }
  let(:group_name) { 'contactinformation' }
  let(:name) { 'hr_test_property_name_1' }

  describe '.add_default_parameters' do
    subject { described_class.add_default_parameters({}) }

    context "default parameters" do
      its([:property]){ should == "email" }
    end
  end

  describe '.all' do
    cassette 'contacts_properties_all'

    subject { described_class.all }

    it 'returns all properties' do
      expect(subject.size).to eq(current_properties_amount)
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.all(logger: logger)
      end
    end
  end

  describe '.find_by_name' do
    cassette 'contacts_properties_find_by_name'

    subject { described_class.find_by_name(name) }
    let(:name) { 'email' }

    it 'finds property' do
      expect(subject.name).to eq(name)
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.find_by_name(name, logger: logger)
      end
    end
  end

  describe '.create!' do
    cassette 'contacts_properties_create'

    subject { described_class.create!(group_name, params) }
    let(:params) { {name: name, type: 'string'} }

    it 'creates property' do
      expect{ subject }.to change{ described_class.all.size }.from(current_properties_amount).to(current_properties_amount + 1)
    end

    it 'returns property' do
      expect(subject.name).to eq(name)
    end
  end

  describe '.delete' do
    cassette 'contacts_properties_delete'

    subject { described_class.delete(name) }
    let(:name) { 'hr_test_property_name_2' }

    before do
      described_class.create!(group_name, {name: name, type: 'string'})
    end

    it 'deletes property' do
      expect(described_class.find_by_name(name)).not_to be_nil
      subject
      expect{ described_class.find_by_name(name) }.to raise_error(Hubspot::RequestError)
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:delete, anything, anything, anything, anything){ true }
        described_class.delete(name, logger: logger)
      end
    end
  end
end