describe Clc::Client, :vcr do
  it 'returns Array' do
    expect(subject.list_servers).to be_an(Array)
  end
end
