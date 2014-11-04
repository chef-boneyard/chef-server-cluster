execute 'create organization' do
  command <<-EOM.gsub(/\s+/, ' ').strip!
    chef-server-ctl org-create #{node['chef-server-cluster']['organization']}
    #{node['chef-server-cluster']['organization_long_name']}
    -a #{node['chef-server-cluster']['admin']['username']}
    -f #{node['chef-server-cluster']['organization_private_key_path']}
  EOM
  not_if "chef-server-ctl org-list | grep -w #{node['chef-server-cluster']['organization']}"
end
