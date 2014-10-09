require 'spec_helper'

describe 'chef-server-cluster::default' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }

  it 'creates the `/etc/opscode` directory' do
    expect(chef_run).to create_directory('/etc/opscode')
  end

  it 'creates the `/etc/opscode-analytics` directory' do
    expect(chef_run).to create_directory('/etc/opscode-analytics')
  end

  it 'installs chef-server-core as a chef_server_ingredient' do
    expect(chef_run).to install_chef_server_ingredient('chef-server-core')
  end
end
