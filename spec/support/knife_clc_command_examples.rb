shared_examples_for 'a Knife CLC command' do
  include_context 'a Knife command'

  context 'considering instance methods' do
    describe '#connection' do
      before(:each) do
        allow(::Clc::Client).to receive(:new) { client }
        allow(command).to receive(:connection).and_call_original
      end

      let(:client) { double }

      it 'returns API client instance' do
        expect(command.connection).to eq(client)
      end
    end

    describe '#run' do
      context 'always' do
        it 'synchronizes stdout' do
          expect($stdout).to receive(:sync=).with(true)
          run.call
        end

        it 'parses parameters' do
          expect(command).to receive(:parse_and_validate_parameters)
          run.call
        end
      end

      context 'when there are errors' do
        before(:each) do
          command.errors << 'Something happened'
          allow(command).to receive(:exit)
        end

        it 'shows errors' do
          expect(command).to receive(:show_errors)
          run.call
        end

        it 'shows usage' do
          expect(command).to receive(:show_usage)
          run.call
        end

        it 'tries to exit' do
          expect(command).to receive(:exit).with(1)
          run.call
        end
      end

      context 'when there are no errors' do
        it 'executes command instructions' do
          expect(command).to receive(:execute)
          command.run
        end
      end
    end
  end
end
