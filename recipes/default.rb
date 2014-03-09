#
# Cookbook Name:: oc-ec
# Attributes:: default
#
# Copyright (C) 2014, Chef
#

## Move this to a library ##
ec_vars = Hash.new
ec_vars[:enabled_svcs]  = []
ec_vars[:disabled_svcs] = []
ec_vars[:vips]          = []

[
  'drbd',
  'couchdb',
  'rabbitmq',
  'postgresql',
  'oc_bifrost',
  'opscode_certificate',
  'opscode_account',
  'opscode_solr',
  'opscode_expander',
  'bootstrap',
  'opscode_org_creator',
  'opscode_chef_mover',
  'bookshelf',
  'opscode_erchef',
  'opscode_webui',
  'nginx',
  'keepalived'
].each do |svc|
  if node['ec'][svc]['enable']
    ec_vars[:enabled_svcs] << svc
    if svc !~ /(opscode_expander|bootstrap|opscode_org_creator|opscode_chef_mover)/
      ec_vars[:vips] << svc
    end
  else
    ec_vars[:disabled_svcs] << svc
  end
end
## End of library ##

package 'private-chef'

directory '/etc/opscode'

template '/etc/opscode/private-chef.rb' do
  source 'private-chef.rb.erb'
  variables :ec_vars => ec_vars
end

execute 'private-chef-ctl reconfigure' do
  action :nothing
  subscribes :run, 'package[private-chef]'
  subscribes :run, 'template[/etc/opscode/private-chef.rb]'
end
