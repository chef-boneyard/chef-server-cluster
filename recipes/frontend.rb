node.default['ec']['role'] = 'frontend'

# TODO: the VIPs should probably come from a more dynamic thing like a
# data bag item, but we need to sort out the HA problem first.
ChefHelpers::FRONTEND_SVCS.each do |svc|
  node.default['ec'][svc]['vip'] = node['ipaddress']
end

%w{opscode-erchef opscode-account opscode-webui oc_bifrost}.map do |svc|
  node.default['lb']['upstream'][svc] = [node['ipaddress']]
end

# Use the helper to find the VIP for the backend nodes in the LB.
node.default['lb']['upstream'] = {
  'opscode-solr' => ChefHelpers.find_vip_for_service('opscode-solr', node),
  'bookshelf' => ChefHelpers.find_vip_for_service('bookshelf', node)
}

node.default['opscode-account']['listen'] = node['ipaddress']
node.default['redis_lb']['bind'] = node['ipaddress']
node.default['oc_bifrost']['listen'] = node['ipaddress']
node.default['opscode-webui']['listen'] = [node['ipaddress'], node['opscode-webui']['port']].join(':')
