require 'chef/knife/clc_operation_show'

describe Chef::Knife::ClcOperationShow do
  let(:valid_argv) { %w(ca1-41967) }

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  let(:operation_id) { 'ca1-41967' }
  let(:operation) { { 'status' => 'succeeded' } }

  before(:each) do
    allow(connection).to receive(:show_operation).
      with(operation_id) { operation }

    allow(connection).to receive(:wait_for) do |&block|
      4.times { block.call }
    end
  end

  context 'considering displayed information' do
    before(:each) { run.call }

    subject(:output) { stdout.string }

    context 'with waiting' do
      let(:argv) { valid_argv.concat(%w(--wait)) }

      it { is_expected.to match(/waiting for operation/i) }
      it { is_expected.to match(/has been completed/) }
      it { is_expected.to_not match(/Status/) }
    end

    context 'without waiting' do
      let(:argv) { valid_argv }

      it { is_expected.to match(/Status/i) }
      it { is_expected.to include(operation['status']) }
    end
  end

  context 'considering command parameters' do
    context 'when they are invalid' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      subject(:output) { stderr.string }

      context 'meaning required ones are missing' do
        it { is_expected.to match(/operation id is required/i) }
      end
    end

    context 'when they are valid' do
      let(:argv) { valid_argv }

      it 'passes them correctly' do
        expect(connection).to receive(:show_operation).
          with(operation_id).
          and_return(operation)

        run.call
      end
    end
  end
end
