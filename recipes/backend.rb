node.default['ec']['role'] = 'backend'
# TODO: the VIPs should probably come from a more dynamic thing like a
# data bag item, but we need to sort out the HA problem first.
node.default['ec'] = {
  'couchdb' => {
    'vip' => node['ipaddress'],
    'bind_address' => node['ipaddress']
  },
  'postgresql' => {
    'vip' => node['ipaddress'],
    'trust_auth_md5_addresses' => [
      '127.0.0.1/32',
      '::1/128',
      # using what we have in prod
      '0.0.0.0/0',
      '::0/0'
    ]
  },
  'bookshelf' => {
    'vip' => node['ipaddress'],
    'listen' => node['ipaddress']
  }
}
