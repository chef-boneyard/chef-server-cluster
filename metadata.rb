name             'chef-server-cluster'
maintainer       'Chef Software, Inc.'
maintainer_email 'ops@getchef.com'
license          'Apache 2.0'
description      'A Chef cookbook from CHEF for managing Chef Server clusters. Turtles.'
source_url 'https://github.com/chef-cookbooks/chef-server-cluster' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/chef-server-cluster/issues' if respond_to?(:issues_url)
version          '0.0.9'
depends          'chef-server-ingredient'
depends          'chef-vault'
