include_recipe 'oc-ec'

# chef_server_ingredient 'opscode-manage' do
#   notifies :reconfigure, 'chef_server_ingredient[opscode-manage]'
# end

# chef_server_ingredient 'opscode-reporting' do
#   notifies :reconfigure, 'chef_server_ingredient[opscode-reporting]'
# end

file '/etc/opscode/private-chef.rb' do
  content <<-EOH
api_fqdn '#{node['fqdn']}'
dark_launch['actions'] = true
rabbitmq['vip'] = '#{node['ipaddress']}'
rabbitmq['node_ip_address'] = '0.0.0.0'
EOH
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
end

# Workaround for https://github.com/opscode/chef-metal/issues/174
file '/etc/opscode-analytics/actions-source.json' do
  mode 00755
end

file'/etc/opscode-analytics/webui_priv.pem' do
  mode 00755
end
