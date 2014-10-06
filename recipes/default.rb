#
# Cookbook Name:: oc-ec
# Recipes:: default
#
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#

directory '/etc/opscode' do
  mode 0755
  recursive true
end

directory '/etc/opscode-analytics' do
  recursive true
end

chef_server_ingredient 'chef-server-core' do
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
end
