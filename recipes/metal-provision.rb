#
# Cookbook Name:: chef-server-cluster
# Recipes:: mtal-provision
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
# This recipe is run on the "provisioning" node. It makes all the other nodes using chef-metal.

include_recipe 'chef-server-cluster::metal'

# This needs to move to a chef_vault_item, and use our internal `data`
# convention for the sub-key of where the secrets are. It should also
# use an attribute for the name, so basically uncomment this line when
# we're ready for that.
#ssh_keys = chef_vault_item('vault', node['chef-server-cluster']['metal-provisioner-key-name'])['data']

#ssh_keys = data_bag_item('secrets', 'hc-metal-provisioner-chef-aws-us-west-2')

key_name = node['chef-server-cluster']['aws']['machine_options']['bootstrap_options']['key_name']
ssh_keys = data_bag_item('secrets', key_name)

directory '/tmp/ssh' do
  recursive true
end

directory '/tmp/stash' do
  recursive true
end

file '/tmp/ssh/id_rsa' do
  content ssh_keys['private_ssh_key']
  sensitive true
end

file '/tmp/ssh/id_rsa.pub' do
  content ssh_keys['public_ssh_key']
  sensitive true
end

fog_key_pair key_name do
  private_key_path '/tmp/ssh/id_rsa'
  public_key_path '/tmp/ssh/id_rsa.pub'
end

machine 'bootstrap-backend' do
  recipe 'chef-server-cluster::bootstrap'
  ohai_hints 'ec2' => '{}'
  action :converge
  converge true
end

%w{ actions-source.json webui_priv.pem }.each do |analytics_file|

  machine_file "/etc/opscode-analytics/#{analytics_file}" do
    local_path "/tmp/stash/#{analytics_file}"
    machine 'bootstrap-backend'
    action :download
  end

end

machine_file '/etc/opscode/webui_pub.pem' do
  local_path '/tmp/stash/webui_pub.pem'
  machine 'bootstrap-backend'
  action :download
end

machine 'frontend' do
  recipe 'chef-server-cluster::frontend'
  ohai_hints 'ec2' => '{}'
  action :converge
  converge true
  files(
        '/etc/opscode/webui_priv.pem' => '/tmp/stash/webui_priv.pem',
        '/etc/opscode/webui_pub.pem' => '/tmp/stash/webui_pub.pem'
       )
end

machine 'analytics' do
  recipe 'chef-server-cluster::analytics'
  ohai_hints 'ec2' => '{}'
  action :converge
  converge true
  files(
        '/etc/opscode-analytics/actions-source.json' => '/tmp/stash/actions-source.json',
        '/etc/opscode-analytics/webui_priv.pem' => '/tmp/stash/webui_priv.pem'
       )
end
