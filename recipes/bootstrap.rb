#
# Cookbook Name:: oc-ec
# Recipes:: bootstrap
#
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#
# This recipe is applied using the `ec-bootstrap` role in
# production-ish systems. The recipe will remove the role, or itself,
# from the node's direct run list at the end of the run.

ec_vars = ChefHelpers.ec_vars(node)

package 'bootstrap-private-chef' do
  package_name 'private-chef'
end

directory 'bootstrap-etc-opscode' do
  path '/etc/opscode'
end

template 'bootstrap-private-chef.rb' do
  path '/etc/opscode/private-chef.rb'
  source 'private-chef.rb.erb'
  variables :ec_vars => ec_vars
end

execute 'bootstrap-reconfigure' do
  command 'private-chef-ctl reconfigure'
  action :nothing
  subscribes :run, 'package[bootstrap-private-chef]', :immediately
  subscribes :run, 'template[bootstrap-private-chef.rb]', :immediately
end

# TODO: https://chef.leankit.com/Boards/View/82275459/101869332
# This horror should be refactored.
secret_files = ChefHelpers.secret_files
data_bag_name = 'bootstrap-secrets'

begin
  data_bag(data_bag_name)
rescue
  ruby_block "create-#{data_bag_name}" do
    block do
      Chef::DataBag.validate_name!(data_bag_name)
      databag = Chef::DataBag.new
      databag.name(data_bag_name)
      databag.save
    end
    action :create
  end
end

secret_files.each do |secret|
  ruby_block "store-generated-secret-#{secret}-#{node.chef_environment}" do
    block do
      databag_item = Chef::DataBagItem.new
      databag_item.data_bag(data_bag_name)
      databag_item.raw_data = {
        'id'=> "#{secret.gsub(/\.[a-z]+/, '_')}_#{node.chef_environment}",
        'data' => IO.read("/etc/opscode/#{secret}")
      }
      databag_item.save
    end
    action :create
  end
end

ruby_block "store-private-chef-secrets-#{node.chef_environment}" do
  block do
    databag_item = Chef::DataBagItem.new
    databag_item.data_bag(data_bag_name)
    databag_item.raw_data = {
      'id' => "private-chef-secrets-#{node.chef_environment}",
      'data' => JSON.parse(IO.read('/etc/opscode/private-chef-secrets.json'))
    }
    databag_item.save
  end
  action :create
end
### Stop the horrors ###

ruby_block 'remove-ec-bootstrap' do
  block do
    Chef::Log.debug('Removing the EC bootstrap recipe and role from the node run list')
    node.run_list.remove('recipe[oc-ec::bootstrap]')
    node.run_list.remove('role[ec-bootstrap]')
  end
  only_if do
    node.run_list.include?('recipe[oc-ec::bootstrap]') || node.run_list.include?('role[ec-bootstrap]')
  end
  action :create
end
