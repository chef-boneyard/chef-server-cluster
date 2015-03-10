#
# Cookbook Name:: chef-server-cluster
# Libraries:: helpers
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
module ChefHelpers
  # returns an array of all the "secrets" files that are automatically
  # generated on an initial `chef-server-ctl reconfigure` run.
  def self.secret_files
    %w{pivotal.cert  pivotal.pem  webui_priv.pem  webui_pub.pem  worker-private.pem  worker-public.pem}
  end

  def self.symbolize_keys_deep!(h)
    Chef::Log.debug("#{h.inspect} is a hash with string keys, make them symbols")
    h.keys.each do |k|
      ks    = k.to_sym
      h[ks] = h.delete k
      symbolize_keys_deep! h[ks] if h[ks].kind_of? Hash
    end
  end

  # We will return the right IP to use depending wheter we need to
  # use the Hostname, Public IP or the Private IP
  def self.get_aws_hostname(node)
    return node['hostname'] unless node['ec2']

    if node['ec2']['public_hostname']
      node['ec2']['public_hostname']
    elsif node['ec2']['public_ipv4']
      node['ec2']['public_ipv4']
    elsif node['ec2']['local_ipv4']
      node['ec2']['local_ipv4']
    else
      node['hostname']
    end
  end
end
