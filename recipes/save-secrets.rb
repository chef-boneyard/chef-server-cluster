#
# Cookbook Name:: chef-server-cluster
# Recipes:: save-secrets
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
# This recipe has bugs and isn't used yet, but I wanted to make it
# available as a starting point.
include_recipe 'chef-vault'

secret_files = ChefHelpers.secret_files
data_bag_name = 'bootstrap-secrets'

chef_gem 'cheffish'
require 'cheffish'
chef_data_bag data_bag_name

secret_files.each do |secret|
  next unless ::File.exist?(::File.join('/etc/opscode', secret))
  chef_vault_secret "store-generated-secret-#{secret}-#{node.chef_environment}" do
    data_bag data_bag_name
    raw_data({
        'id'=> "#{secret.gsub(/\.[a-z]+/, '_')}_#{node.chef_environment}",
        'data' => IO.read("/etc/opscode/#{secret}")
    })
    admins 'admin'
    search '*:*'
  end
end
