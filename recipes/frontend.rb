include_recipe 'oc-ec'
include_recipe 'chef-vault'

node.default['ec']['role'] = 'frontend'

ec_servers = search('node', 'ec_role:frontend OR ec_role:backend')

ec_vars = {
           topology: 'tier',
           disabled_svcs: [],
           enabled_svcs: [],
           vips: {},
           api_fqdn: 'manage.chef.sh',
           notification_email: 'ops@chef.io',
           servers: ec_servers
          }

node.default['ec'].merge!(ec_vars)

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :ec_vars => ec_vars
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
end

chef_server_ingredient 'opscode-manage' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-manage]'
end

chef_server_ingredient 'opscode-reporting' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-reporting]'
end

