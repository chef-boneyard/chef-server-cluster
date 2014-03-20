#
# Cookbook Name:: oc-ec
# Recipes:: default
#
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#

ec_vars = ChefHelpers.ec_vars(node['ec'])

package 'private-chef'

directory '/etc/opscode'

template '/etc/opscode/private-chef.rb' do
  source 'private-chef.rb.erb'
  variables :ec_vars => ec_vars
end

execute 'reconfigure' do
  command 'private-chef-ctl reconfigure'
  action :nothing
  subscribes :run, 'package[private-chef]'
  subscribes :run, 'template[/etc/opscode/private-chef.rb]'
end
