require 'chef/knife/clc_base'

class DummyCommand < Chef::Knife
  include Chef::Knife::ClcBase
end

describe DummyCommand do
  subject(:command) { described_class.new }

  describe '#connection' do
    before(:each) do
      allow(::Clc::Client).to receive(:new) { client }
    end

    let(:client) { double }

    it 'returns API client instance' do
      expect(command.connection).to eq(client)
    end
  end

  describe '#check_for_errors!' do
    before(:each) do
      allow(command).to receive(:show_usage)
      allow(command).to receive(:exit)
      allow(command).to receive(:ui) { ui }
      allow(ui).to receive(:error)
    end

    let(:ui) { double }
    let(:errors) { command.errors }

    context 'when there are errors' do
      before(:each) do
        errors << 'Something went wrong'
        errors << 'Something else went wrong'
      end

      it 'tries to exit the program' do
        expect(command).to receive(:exit).with(1)
        command.check_for_errors!
      end

      it 'prints every error' do
        expect(ui).to receive(:error).with('Something went wrong')
        expect(ui).to receive(:error).with('Something else went wrong')
        command.check_for_errors!
      end
    end

    context 'when there are no errors' do
      it 'returns nil' do
        expect(command.check_for_errors!).to be_nil
      end
    end
  end

  describe '#run' do
    it 'syncrhonizes stdout' do
      expect($stdout).to receive(:sync=).with(true)
      command.run
    end

    it 'checks for errors' do
      expect(command).to receive(:check_for_errors!)
      command.run
    end

    it 'executes command instructions' do
      expect(command).to receive(:execute)
      command.run
    end
  end
end
