#
# Cookbook Name:: oc-ec
# Recipes:: bootstrap
#
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#
include_recipe 'oc-ec'
include_recipe 'chef-vault'

node.default['ec']['role'] = 'backend'
node.default['ec']['bootstrap']['enable'] = true

# It's easier to deal with a hash rather than a data bag item, since
# we're not going to need any of the methods, we just need raw data.
ec_vars = data_bag_item('chef_server', 'topology').to_hash
ec_vars.delete('id')

ec_servers = search('node', 'ec_role:backend').map do |server|
  {
    fqdn: server['fqdn'],
    ipaddress: server['ipaddress'],
    bootstrap: server['ec']['bootstrap']['enable'],
    role: server['ec']['role']
  }
end

# If we didn't get search results, then populate with ourself (we're
# bootstrapping after all)
if ec_servers.empty?
  ec_servers = [{
                 fqdn: node['fqdn'],
                 ipaddress: node['ipaddress'],
                 bootstrap: true,
                 role: 'backend'
                }]
end

ec_vars['vips'] = { 'rabbitmq' => node['ipaddress'] }
ec_vars['rabbitmq'] = { 'node_ip_address' => '0.0.0.0' }

node.default['ec'].merge!(ec_vars)

# TODO: (jtimberman) chef_vault_item?
chef_secrets = data_bag_item('secrets', "private-chef-secrets-#{node.chef_environment}")['data']

file "/etc/opscode/private-chef-secrets.json" do
  content JSON.pretty_generate(chef_secrets)
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
end

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :ec_vars => node['ec'], :ec_servers => ec_servers
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
end

secret_files = ChefHelpers.secret_files
data_bag_name = 'bootstrap-secrets'

chef_gem 'cheffish'
require 'cheffish'
chef_data_bag data_bag_name

# secret_files.each do |secret|
#   next unless ::File.exist?(::File.join('/etc/opscode', secret))
#   chef_vault_secret "store-generated-secret-#{secret}-#{node.chef_environment}" do
#     data_bag data_bag_name
#     raw_data({
#         'id'=> "#{secret.gsub(/\.[a-z]+/, '_')}_#{node.chef_environment}",
#         'data' => IO.read("/etc/opscode/#{secret}")
#     })
#     admins 'admin'
#     search '*:*'
#   end
# end

file '/etc/opscode-analytics/actions-source.json' do
  mode 00644
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end

file'/etc/opscode-analytics/webui_priv.pem' do
  mode 00644
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end
