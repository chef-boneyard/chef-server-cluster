#
# Cookbook Name:: chef-server-cluster
# Recipes:: cluster-provision
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
# This recipe is run on the provisioner node. It creates all the other nodes using chef-provisioning.

include_recipe 'chef-server-cluster::setup-provisioner'
include_recipe 'chef-server-cluster::setup-ssh-keys'

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

%w{ pivotal.pem webui_pub.pem }.each do |opscode_file|

  machine_file "/etc/opscode/#{opscode_file}" do
    local_path "/tmp/stash/#{opscode_file}"
    machine 'bootstrap-backend'
    action :download
  end

end

machine 'frontend' do
  recipe 'chef-server-cluster::frontend'
  ohai_hints 'ec2' => '{}'
  action :converge
  converge true
  files(
        '/etc/opscode/webui_priv.pem' => '/tmp/stash/webui_priv.pem',
        '/etc/opscode/webui_pub.pem' => '/tmp/stash/webui_pub.pem',
        '/etc/opscode/pivotal.pem' => '/tmp/stash/pivotal.pem'
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
