organization                  = node['chef-server-cluster']['organization']
organization_long_name        = node['chef-server-cluster']['organization_long_name']
admin_username                = node['chef-server-cluster']['admin']['username']
organization_private_key_path = node['chef-server-cluster']['organization_private_key_path']

execute 'create organization' do
  command <<-EOM.gsub(/\s+/, ' ').strip!
    chef-server-ctl org-create #{organization}
    #{organization_long_name}
    -a #{admin_username}
    > #{organization_private_key_path}
  EOM
  not_if "chef-server-ctl org-list | grep -w #{organization}"
end