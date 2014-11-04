username          = node['chef-server-cluster']['admin']['username']
firstname         = node['chef-server-cluster']['admin']['firstname']
lastname          = node['chef-server-cluster']['admin']['lastname']
email             = node['chef-server-cluster']['admin']['email']
password          = node['chef-server-cluster']['admin']['password']
private_key_path  = node['chef-server-cluster']['admin']['private_key_path']

execute 'create admin' do
  command <<-EOM.gsub(/\s+/, ' ').strip!
    chef-server-ctl user-create #{username}
    #{firstname}
    #{lastname}
    #{email}
    #{password}
    -f #{private_key_path}
  EOM
  not_if "chef-server-ctl user-list | grep -w #{username}"
end