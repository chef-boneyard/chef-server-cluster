#
# Cookbook Name:: chef-server-cluster
# Recipes:: standalone
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

# TODO: (jtimberman) These (manage, reporting) would probably be run
# on separate machines in a future version of this cookbook, or at
# least configurable by the topology.
chef_server_ingredient 'opscode-manage' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-manage]'
end

chef_server_ingredient 'opscode-reporting' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-reporting]'
end

file '/etc/opscode/private-chef.rb' do
  content <<-EOH
api_fqdn '#{node['fqdn']}'
dark_launch['actions'] = true
rabbitmq['vip'] = '#{node['ipaddress']}'
rabbitmq['node_ip_address'] = '0.0.0.0'
EOH
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
end

# These two resources set permissions on the files to make them
# readable as a workaround for
# https://github.com/opscode/chef-provisioning/issues/174
file '/etc/opscode-analytics/actions-source.json' do
  mode 00755
end

file '/etc/opscode-analytics/webui_priv.pem' do
  mode 00755
end
