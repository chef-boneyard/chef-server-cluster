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

ec_servers = search('node', 'ec_role:frontend OR ec_role:backend').map do |server|
  {
    fqdn: server['fqdn'],
    ipaddress: server['ipaddress'],
    bootstrap: server['ec']['bootstrap']['enable'],
    role: server['ec']['role']
  }
end

if ec_servers.empty?
  ec_servers = [{
                 fqdn: node['fqdn'],
                 ipaddress: node['ipaddress'],
                 bootstrap: true,
                 role: 'backend'
                }]
end

ec_vars = {
           topology: 'tier',
           disabled_svcs: [],
           enabled_svcs: [],
           vips: {
                  rabbitmq: node['ipaddress']
                 },
           rabbitmq_node_ip_address: '0.0.0.0',
           dark_launch_actions: true,
           bootstrap: {
                       enable: true
                      },
           servers: ec_servers
         }

node.default['ec'].merge!(ec_vars)

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :ec_vars => ec_vars
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
end

secret_files = ChefHelpers.secret_files
data_bag_name = 'bootstrap-secrets'

chef_gem 'cheffish'
require 'cheffish'
chef_data_bag data_bag_name

secret_files.each do |secret|
  next unless ::File.exist?(secret)
  chef_vault_secret "store-generated-secret-#{secret}-#{node.chef_environment}" do
    data_bag data_bag_name
    raw_data({
        'id'=> "#{secret.gsub(/\.[a-z]+/, '_')}_#{node.chef_environment}",
        'data' => IO.read("/etc/opscode/#{secret}")
    })
    admins nil
    search '*:*'
  end
end

file '/etc/opscode-analytics/actions-source.json' do
  mode 00644
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end

file'/etc/opscode-analytics/webui_priv.pem' do
  mode 00644
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end
