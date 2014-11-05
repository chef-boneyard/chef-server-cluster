execute 'create admin' do
  command <<-EOM.gsub(/\s+/, ' ').strip!
    chef-server-ctl user-create #{node['chef-server-cluster']['admin']['username']}
    #{node['chef-server-cluster']['admin']['firstname']}
    #{node['chef-server-cluster']['admin']['lastname']}
    #{node['chef-server-cluster']['admin']['email']}
    #{node['chef-server-cluster']['admin']['password']}
    -f #{node['chef-server-cluster']['admin']['private_key_path']}
  EOM
  not_if "chef-server-ctl user-list | grep -w #{node['chef-server-cluster']['admin']['username']}"
end
