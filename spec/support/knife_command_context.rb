require 'chef'
require 'chef/knife'

shared_context 'a Knife command' do
  let(:argv) { [] }
  let(:command) { described_class.new(argv) }
  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }
  let(:ui) { double }
  let(:connection) { double }

  subject(:run) { -> { command.run } }

  before(:each) do
    Chef.reset!
    Chef::Config.reset
    allow(command).to receive(:config_file_settings) { {} }
    command.configure_chef

    allow(command).to receive(:exit) do |code|
      unless code.zero?
        raise "SystemExit: #{command.errors.inspect}"
      end
    end

    allow(command).to receive(:puts) { |text| stdout.puts text }
    allow(command).to receive(:putc) { |char| stdout.putc char }
    allow(command).to receive(:stdout) { stdout }
    allow(command).to receive(:stderr) { stderr }
    allow(command).to receive(:ui) { ui }
    allow(ui).to receive(:info) { |text| stdout.puts text }
    allow(ui).to receive(:error) { |text| stderr.puts text }
    allow(ui).to receive(:color) { |text, color| text }

    allow(command).to receive(:connection) { connection }
  end
end
