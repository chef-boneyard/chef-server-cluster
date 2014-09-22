# This recipe is run on the "provisioning" node. It makes all the other nodes using chef-metal.

include_recipe 'oc-ec::metal'
ssh_keys = data_bag_item('secrets', 'hc-metal-provisioner-chef-aws-us-west-2')

directory '/tmp/ssh' do
  recursive true
end

directory '/tmp/stash' do
  recursive true
end

file '/tmp/ssh/hc-metal-provisioner' do
  content ssh_keys['private_ssh_key']
  sensitive true
end

file '/tmp/ssh/hc-metal-provisioner.pub' do
  content ssh_keys['public_ssh_key']
  sensitive true
end

link '/tmp/ssh/id_rsa' do
  to '/tmp/ssh/hc-metal-provisioner'
end

link '/tmp/ssh/id_rsa.pub' do
  to '/tmp/ssh/hc-metal-provisioner.pub'
end

fog_key_pair 'hc-metal-provisioner' do
  private_key_path '/tmp/ssh/hc-metal-provisioner'
  public_key_path '/tmp/ssh/hc-metal-provisioner.pub'
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

