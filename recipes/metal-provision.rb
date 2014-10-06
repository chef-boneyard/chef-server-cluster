# This recipe is run on the "provisioning" node. It makes all the other nodes using chef-metal.

include_recipe 'oc-ec::metal'
# This needs to move to a chef_vault_item, and use our `data`
# convention for the sub-key of where the secrets are. It should also
# use an attribute for the name, so basically uncomment this line when
# we're ready for that.
#ssh_keys = chef_vault_item('vault', node['oc-ec']['metal-provisioner-key-name'])['data']
ssh_keys = data_bag_item('secrets', 'hc-metal-provisioner-chef-aws-us-west-2')

directory '/tmp/ssh' do
  recursive true
end

directory '/tmp/stash' do
  recursive true
end

file '/tmp/ssh/id_rsa' do
  content ssh_keys['private_ssh_key']
  sensitive true
end

file '/tmp/ssh/id_rsa.pub' do
  content ssh_keys['public_ssh_key']
  sensitive true
end

fog_key_pair 'hc-metal-provisioner' do
  private_key_path '/tmp/ssh/id_rsa'
  public_key_path '/tmp/ssh/id_rsa.pub'
end

machine 'bootstrap-backend' do
  ohai_hints 'ec2' => {}
  recipe 'oc-ec::bootstrap'
  action :converge
  converge true
end

machine 'frontend' do
  ohai_hints 'ec2' => {}
  recipe 'oc-ec::frontend'
  action :converge
  converge true
end

%w{ actions-source.json webui_priv.pem }.each do |analytics_file|

  machine_file "/etc/opscode-analytics/#{analytics_file}" do
    local_path "/tmp/stash/#{analytics_file}"
    machine 'bootstrap-backend'
    action :download
  end

end

machine 'analytics' do
  recipe 'oc-ec::analytics'
  action :converge
  converge true
  files({
         '/etc/opscode-analytics/actions-source.json' => '/tmp/stash/actions-source.json',
         '/etc/opscode-analytics/webui_priv.pem' => '/tmp/stash/webui_priv.pem'
        })
end

