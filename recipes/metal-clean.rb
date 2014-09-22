include_recipe 'oc-ec::metal'
machine 'analytics' do
  action :destroy
end

machine 'bootstrap-backend' do
  action :destroy
end

directory '/tmp/ssh' do
  recursive true
  action :delete
end

directory '/tmp/stash' do
  recursive true
  action :delete
end
