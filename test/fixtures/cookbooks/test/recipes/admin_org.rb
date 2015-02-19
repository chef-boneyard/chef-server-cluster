
chef_server_cluster_user 'flock' do
  firstname 'Florian'
  lastname 'Lock'
  email 'ops@example.com'
  password 'DontUseThis4Real'
  private_key_path '/tmp/flock.pem'
  action :create
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
end

chef_server_cluster_org 'example' do
  org_long_name 'Example Organization'
  org_private_key_path '/tmp/example-validator.pem'
  action :create
  notifies :reconfigure, 'chef_server_ingredient[chef-server-core]'
end

chef_server_cluster_org 'example' do
  admins %w{ flock }
  action :add_admin
end