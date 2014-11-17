#
# Cookbook Name:: chef-server-cluster
# Attributes:: default
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
default['chef-server-cluster']['topology'] = 'tier'
default['chef-server-cluster']['role'] = 'frontend'
default['chef-server-cluster']['bootstrap']['enable'] = false
default['chef-server-cluster']['chef-provisioner-key-name'] = 'hc-metal-provisioner-chef-aws-us-west-2'

# these use _ instead of - because it maps to the machine_options in
# chef-provisioning-fog.
default['chef-server-cluster']['aws']['region'] = 'us-west-2'
default['chef-server-cluster']['aws']['machine_options'] = {
                      :ssh_username => 'ubuntu',
                      :use_private_ip_for_ssh => false,
                      :bootstrap_options => {
                                             :key_name => 'hc-metal-provisioner',
                                             :image_id => 'ami-b99ed989',
                                             :flavor_id => 'm3.medium'
                                            }
                    }
