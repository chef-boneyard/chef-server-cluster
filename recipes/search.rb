# TODO: the VIPs should probably come from a more dynamic thing like a
# data bag item, but we need to sort out the HA problem first.
node.default['ec'] = {
  'opscode_solr' => {
    'vip' => node['ipaddress'],
    'ip_address' => node['ipaddress']
  },
  'rabbitmq' => {
    'vip' => node['ipaddress'],
    'node_ip_address' => node['ipaddress']
  }
}
