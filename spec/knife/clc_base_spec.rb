require 'chef/knife'
require 'chef/knife/clc_base'

class DummyCommand < Chef::Knife
  include Chef::Knife::ClcBase
end

describe DummyCommand do
  it_behaves_like 'a Knife CLC command'
end
