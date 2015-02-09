#
# Cookbook Name:: chef-server-cluster
# Recipes:: bootstrap
#
# Author: Joshua Timberman <joshua@getchef.com>
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe 'chef-server-cluster'
include_recipe 'chef-vault'

node.default['chef-server-cluster']['role'] = 'backend'
node.default['chef-server-cluster']['bootstrap']['enable'] = true

# TODO: (jtimberman) chef_vault_item. We sort this so we don't
# get regenerated content in the private-chef-secrets.json later.
chef_secrets      = Hash[data_bag_item('secrets', "private-chef-secrets-#{node.chef_environment}")['data'].sort]
reporting_secrets = Hash[data_bag_item('secrets', "opscode-reporting-secrets-#{node.chef_environment}")['data'].sort]

# It's easier to deal with a hash rather than a data bag item, since
# we're not going to need any of the methods, we just need raw data.
chef_server_config = data_bag_item('chef_server', 'topology').to_hash
chef_server_config.delete('id')

# TODO: (jtimberman) Replace this with partial_search.
chef_servers = search('node', 'chef-server-cluster_role:backend').map do |server| #~FC003
  {
    :fqdn => server['fqdn'],
    :ipaddress => server['ipaddress'],
    :bootstrap => server['chef-server-cluster']['bootstrap']['enable'],
    :role => server['chef-server-cluster']['role']
  }
end

# If we didn't get search results, then populate with ourself (we're
# bootstrapping after all)
if chef_servers.empty?
  chef_servers = [
                  {
                    :fqdn => node['fqdn'],
                    :ipaddress => node['ipaddress'],
                    :bootstrap => true,
                    :role => 'backend'
                  }
                 ]
end

chef_server_config['vips'] = { 'rabbitmq' => node['ipaddress'] }
chef_server_config['rabbitmq'] = { 'node_ip_address' => '0.0.0.0' }

node.default['chef-server-cluster'].merge!(chef_server_config)

file '/etc/opscode/private-chef-secrets.json' do
  content JSON.pretty_generate(chef_secrets)
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
  sensitive true
end

file '/etc/opscode-reporting/opscode-reporting-secrets.json' do
  content JSON.pretty_generate(reporting_secrets)
  notifies :reconfigure, 'chef_server_ingredient[opscode-reporting]'
  sensitive true
end

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :chef_server_config => node['chef-server-cluster'], :chef_servers => chef_servers
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
  notifies :run, 'execute[chef-server-ctl restart rabbitmq]'
end

# This is to work around an issue where rabbitmq doesn't always listen
# on 0.0.0.0 after `reconfigure` despite the configuration above.
execute 'chef-server-ctl restart rabbitmq' do
  action :nothing
end

# These two resources set permissions on the files to make them
# readable as a workaround for
# https://github.com/opscode/chef-provisioning/issues/174
file '/etc/opscode-analytics/actions-source.json' do
  mode 00644
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end

file'/etc/opscode-analytics/webui_priv.pem' do
  mode 00644
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end

file '/etc/opscode/pivotal.pem' do
  mode 00644
  # without this guard, we create an empty file, causing bootstrap to
  # not actually work, as it checks the presence of this file.
  only_if { ::File.exists?('/etc/opscode/pivotal.pem') }
  subscribes :create, 'chef_server_ingredient[chef-server-core]', :immediately
end

chef_server_ingredient 'opscode-reporting' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-reporting]'
end
