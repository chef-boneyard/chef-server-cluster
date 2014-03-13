#
# Cookbook Name:: oc-ec
# Attributes:: default
#
# Copyright (C) 2014, Chef
#

## Move this to a library ##
ec_vars = {}
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

backend_svcs = ['drbd', 'couchdb', 'rabbitmq', 'postgresql', 'opscode_expander', 'opscode_solr']
frontend_svcs = ['nginx', 'oc_bifrost', 'opscode_account', 'opscode-certificate', 'opscode_erchef']

if !(ec_vars[:enabled_svcs] & backend_svcs).empty?
  ec_vars[:role] = 'backend'
elsif !(ec_vars[:enabled_svcs] & frontend_svcs).empty?
  ec_vars[:role] = 'frontend'
end
## End of library ##

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
