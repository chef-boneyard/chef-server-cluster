# Maybe we'll use a data bag to store these
analytics_fqdn = node['ec2']['public_hostname']
node.default['ec']['role'] = 'analytics'

directory '/etc/opscode' do
  recursive true
end

directory '/etc/opscode-analytics' do
  recursive true
end

file '/etc/opscode-analytics/opscode-analytics.rb' do
  content "topology 'standalone'\nanalytics_fqdn '#{node['ec2']['public_hostname']}'"
  notifies :reconfigure, 'chef_server_ingredient[opscode-analytics]'
end

chef_server_ingredient 'opscode-analytics' do
  notifies :reconfigure, 'chef_server_ingredient[opscode-analytics]'
end
