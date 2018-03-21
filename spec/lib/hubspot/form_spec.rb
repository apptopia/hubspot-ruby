describe Hubspot::Form do
  let(:example_form_hash) do
    VCR.use_cassette("form_example", record: :none) do
      HTTParty.get("https://api.hubapi.com/contacts/v1/forms/c4189ed5-c056-400d-8e11-63c103c4b422/?hapikey=demo").parsed_response
    end
  end
  let(:created_guid) { '7f82048b-1364-4158-8a59-166e70df42c6' }
  let(:logger) { mock('logger') }

  before { Hubspot.configure(hapikey: "demo", portal_id: '62515') }

  describe '.initialize' do
    subject { described_class.new(example_form_hash) }

    it { should be_an_instance_of described_class }
    its(:guid) { should be_a(String) }
    its(:properties) { should be_a(Hash) }
  end

  describe '.all' do
    cassette 'find_all_forms'

    it 'returns all forms' do
      forms = described_class.all
      expect(forms.count).to eq(10)

      form = forms.first
      expect(form).to be_a(described_class)
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.all(logger: logger)
      end
    end
  end

  describe '.create' do
    subject{ described_class.create!(params) }

    context 'with all required parameters' do
      cassette 'create_form'

      let(:params) do
        {
          name: "Demo Form #{Time.now.to_i}",
          action: "",
          method: "POST",
          cssClass: "hs-form stacked",
          redirect: "",
          submitText: "Sign Up",
          followUpId: "",
          leadNurturingCampaignId: "",
          notifyRecipients: "",
          embeddedCode: ""
        }
      end
      it { should be_an_instance_of described_class }
      its(:guid) { should eq(created_guid) }

      context 'with logger' do
        it 'logs request' do
          params.merge!(logger: logger)
          mock(logger).log(:post, anything, anything, anything, anything){ true }
          subject
        end
      end
    end

    context 'without all required parameters' do
      cassette 'fail_to_create_form'

      it 'raises an error' do
        expect { described_class.create!({}) }.to raise_error(Hubspot::RequestError)
      end
    end
  end

  describe '.find' do
    cassette "form_find"
    subject { described_class.find(guid) }
    let(:guid) { 'c4189ed5-c056-400d-8e11-63c103c4b422' }

    context 'when the form is found' do
      it { should be_an_instance_of described_class }
      its(:fields) { should_not be_empty }
    end

    context 'when the form is not found' do
      it 'raises an error' do
        expect { described_class.find(-1) }.to raise_error(Hubspot::RequestError)
      end
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:get, anything, anything, anything, anything){ true }
        described_class.find(guid, logger: logger)
      end
    end
  end

  describe '.fields' do
    context 'returning all the fields' do
      cassette 'fields_among_form'

      let(:form) { described_class.new(example_form_hash) }

      it 'returns by default the fields property if present' do
        fields = form.fields
        fields.size.should eq(6)
      end

      it 'updates the fields property and returns it' do
        fields = form.fields(bypass_cache: true)
        fields.size.should eq(5)
      end

      context 'with logger' do
        it 'logs request' do
          mock(logger).log(:get, anything, anything, anything, anything){ true }
          fields = form.fields(bypass_cache: true, logger: logger)
        end
      end
    end

    context 'returning an uniq field' do
      cassette 'field_among_form'

      let(:form) { described_class.new(example_form_hash) }

      it 'returns by default the field if present as a property' do
        field = form.fields(only: :email)
        expect(field).to be_a(Hash)
        expect(field['name']).to be == 'email'
      end

      it 'makes an API request if specified' do
        field = form.fields(only: :email, bypass_cache: true)
        expect(field).to be_a(Hash)
        expect(field['name']).to be == 'email'
      end

      context 'with logger' do
        it 'logs request' do
          mock(logger).log(:get, anything, anything, anything, anything){ true }
          fields = form.fields(only: :email, bypass_cache: true, logger: logger)
        end
      end
    end
  end

  describe '.submit' do
    cassette 'form_submit_data'

    let(:form) { described_class.find(created_guid) }
    let(:params) { {} }

    it 'returns true if the form submission is successfull' do
      result = form.submit(params)
      result.should be true
    end

    it 'returns false in case of errors' do
      Hubspot.configure(hapikey: "demo", portal_id: '62514')
      result = form.submit(params)
      result.should be false
    end

    context 'with logger' do
      let(:params) { {logger: logger} }

      it 'logs request' do
        mock(logger).log(:post, anything, anything, anything, anything){ true }
        form.submit(params)
      end
    end
  end

  describe '.update!' do
    cassette "form_update"

    let(:redirect) { 'http://hubspot.com' }
    let(:new_name) { "updated form name #{created_guid}" }
    let(:form) { described_class.find(created_guid) }
    let(:params) { { name: new_name, redirect: redirect } }
    subject { form.update!(params) }

    it { should be_an_instance_of described_class }
    it 'updates properties' do
      subject.properties['name'].should be == new_name
      subject.properties['redirect'].should be == redirect
    end

    context 'with logger' do
      let(:params) { {logger: logger} }

      it 'logs request' do
        params.merge!(logger: logger)
        mock(logger).log(:post, anything, anything, anything, anything){ true }
        subject
      end
    end
  end

  describe '.create_or_update!' do
    subject { described_class.create_or_update!(params) }
    let(:params) { {name: name, submitText: 'New submit text'} }

    context 'for existing form' do
      cassette 'form_create_or_update-update'

      let(:name) { '1234zz' }

      it 'updates existing form' do
        forms = described_class.all(limit: 10)
        stub(described_class).all{ forms }
        form = forms.find{ |form| form.properties['name'] == name }
        mock(form).update!(params){ true }
        subject
      end

      context 'with logger' do
        let(:params) { {logger: logger, name: name, submitText: 'New submit text'} }

        it 'calls .all and .update! with logger' do
          forms = described_class.all(limit: 10)
          form = forms.find{ |form| form.properties['name'] == name }

          mock(described_class).all(logger: logger){ forms }
          mock(form).update!(params){ true }
          subject
        end
      end
    end

    context 'for not existing form' do
      cassette 'form_create_or_update-create'

      let(:name) { 'fdsg6h45' }

      it 'creates new form' do
        forms = described_class.all(limit: 10)
        stub(described_class).all{ forms }
        mock(described_class).create!(params){ true }
        subject
      end

      context 'with logger' do
        let(:params) { {logger: logger, name: name, submitText: 'New submit text'} }

        it 'calls .all and .create! with logger' do
          forms = described_class.all(limit: 10)

          mock(described_class).all(logger: logger){ forms }
          mock(described_class).create!(params){ true }
          subject
        end
      end
    end
  end

  describe '.destroy!' do
    cassette "form_destroy"

    # NOTE: form previous created via the create! method
    let(:form) { described_class.find(created_guid) }
    subject{ form.destroy! }
    it { should be_true }

    it "should be destroyed" do
      subject
      form.destroyed?.should be_true
    end

    context 'with logger' do
      it 'logs request' do
        mock(logger).log(:delete, anything, anything, anything, anything){ true }
        form.destroy!(logger: logger)
      end
    end
  end
end