# chef-metal-fog depends on chef-metal and cheffish.
chef_gem 'chef-metal-fog'
require 'chef_metal_fog'

with_driver("fog:AWS:default:us-west-2")
with_machine_options({
                      :ssh_username => 'ubuntu',
                      :use_private_ip_for_ssh => false,
                      :bootstrap_options => {
                                             :key_name => 'hc-metal-provisioner',
                                             :image_id => 'ami-b99ed989',
                                             :flavor_id => 'm3.medium'
                                            }
                     })
