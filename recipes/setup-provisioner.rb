#
# Cookbook Name:: chef-server-cluster
# Recipes:: setup-provisioner
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
node['chef-server-cluster']['driver']['gems'].each do |g|
  chef_gem g['name'] do
    compile_time true if Chef::Resource::ChefGem.method_defined?(:compile_time)
  end

  require g['require'] if g.key?('require')
end

# We're not doing anything special with regard to authentication
# options here. WRT AWS, this assumes a default of ~/.aws/config.
provisioner_machine_opts = node['chef-server-cluster']['driver']['machine_options'].to_hash
ChefHelpers.symbolize_keys_deep!(provisioner_machine_opts)

with_driver(node['chef-server-cluster']['driver']['with-parameter'])
with_machine_options(provisioner_machine_opts)
