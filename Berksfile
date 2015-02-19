source 'https://supermarket.chef.io'

metadata

group :integration do
  cookbook 'test', :path => 'test/fixtures/cookbooks/test'
end

# This cookbook isn't on supermarket.
cookbook 'chef-server-ingredient', github: 'stephenlauck/chef-server-ingredient', branch: 'reconfigure_parameter_for_install'
