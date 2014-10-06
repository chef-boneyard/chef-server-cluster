include_recipe 'oc-ec'
include_recipe 'chef-vault'

node.default['ec']['role'] = 'frontend'

ec_vars = data_bag_item('chef_server', 'topology')
ec_vars.delete('id')

# TODO: (jtimberman) chef_vault_item?
chef_secrets = data_bag_item('secrets', "private-chef-secrets-#{node.chef_environment}")['data']

ec_servers = search('node', 'ec_role:backend').map do |server|
  {
    fqdn: server['fqdn'],
    ipaddress: server['ipaddress'],
    bootstrap: server['ec']['bootstrap']['enable'],
    role: server['ec']['role']
  }
end

ec_servers << {
               fqdn: node['fqdn'],
               ipaddress: node['ipaddress'],
               bootstrap: false,
               role: 'frontend'
              }

node.default['ec'].merge!(ec_vars)

template '/etc/opscode/chef-server.rb' do
  source 'chef-server.rb.erb'
  variables :ec_vars => ec_vars, :ec_servers => ec_servers
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]', :immediately
end

file "/etc/opscode/private-chef-secrets.json" do
  content JSON.pretty_generate(chef_secrets)
end

# ChefHelpers.secret_files.each do |secret|
#   secret_id = "#{secret.gsub(/\\.[a-z]+/, '_')}_#{node.chef_environment}"
#   secret_content = chef_vault_item('bootstrap-secrets', secret_id)['data']

#   file "/etc/opscode/#{secret}" do
#     content secret_content
#   end
# end

chef_server_ingredient 'opscode-manage' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-manage]'
end

chef_server_ingredient 'opscode-reporting' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-reporting]'
end
