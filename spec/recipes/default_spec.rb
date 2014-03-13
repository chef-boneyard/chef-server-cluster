require 'spec_helper'

# Write unit tests with ChefSpec - https://github.com/sethvargo/chefspec#readme
describe 'oc-ec::default' do
  let(:chef_run) { ChefSpec::Runner.new.converge(described_recipe) }
  let(:reconfig) { chef_run.execute('reconfigure') }

  it 'installs private-chef package' do
    expect(chef_run).to install_package('private-chef')
  end

  it 'creates the `/etc/opscode` directory' do
    expect(chef_run).to create_directory('/etc/opscode')
  end

  it 'creates the template `/etc/opscode/private-chef.rb`' do
    expect(chef_run).to create_template('/etc/opscode/private-chef.rb')
  end

  it 'executes a `private-chef-ctl reconfigure` on change' do
    expect(reconfig).to subscribe_to('package[private-chef]')
    expect(reconfig).to subscribe_to('template[/etc/opscode/private-chef.rb]')
  end
end
