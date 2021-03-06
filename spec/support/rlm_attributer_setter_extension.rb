RSpec.shared_examples "RlmAttributeSetterExtensions" do

  specify('.rlm_module_name_for_config') do
    expect(described_class.rlm_module_name_for_config).to eq(described_class.name.split('::').last.underscore)
  end

  specify('.required_entries_from_config') do
    expect(described_class.required_entries_from_config).to eq(RLM::Setup.yaml_config['modules']['setup'][described_class.rlm_module_name_for_config]['entries'])
  end

  specify('.to_create_classname_from_config') do
    expect(described_class.to_create_classname_from_config).to eq(RLM::Setup.yaml_config['modules']['setup'][described_class.rlm_module_name_for_config]['class_name'].constantize)
  end

  context('.default_data_attributes') do
    before do
      expect(described_class).to receive(:identify_column).and_return('column')
      expect(RLM::Setup).to receive(:name_for).with('some_attribute', current_module_scope: described_class.rlm_module_name_for_config).and_return('value')
    end

    specify { expect(described_class.default_data_attributes('some_attribute')).to eq('column' => 'value') }
  end

  described_class.required_entries_from_config.each do |entry_name|
    describe ".#{entry_name}" do

      let(:entry) { described_class.to_create_classname_from_config.new }

      context 'create a new entry' do
        before do
          expect(described_class.to_create_classname_from_config).to receive(:find_or_initialize_by).with(described_class.combined_data_attributes(entry_name)).and_return(entry)
          expect(entry).to receive(:new_record?).and_return(true)
          expect(entry).to receive('name=').with(described_class.human_entry_name(entry_name))
          expect(entry).to receive(:save)
        end

        specify { expect(described_class.send(entry_name)).to  eq(entry) }
      end
    end
  end

  describe '.all' do
    specify 'creates and persists all entries' do
      expect(described_class.all.select {|e| e.persisted? }.size).to eq(described_class.required_entries_from_config.size)
    end

    specify 'creates all entries with expect type' do
      expect(described_class.all.map {|e| e.class }.uniq).to match_array([described_class.to_create_classname_from_config])
    end
  end


end