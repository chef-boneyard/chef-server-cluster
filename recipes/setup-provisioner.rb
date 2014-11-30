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
# chef-provisioning-fog depends on chef-provisioning and cheffish.
chef_gem 'chef-provisioning-fog'
chef_gem 'chef-provisioning-aws'
require 'chef/provisioning/fog_driver/driver'

# This requires that the desired AWS account to use is configured in
# ~/.aws/config as `default`.
with_driver("fog:AWS:default:#{node['chef-server-cluster']['aws']['region']}")
with_machine_options(node['chef-server-cluster']['aws']['machine_options'])
