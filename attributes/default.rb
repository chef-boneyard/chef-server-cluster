#
# Cookbook Name:: oc-ec
# Attributes:: default
#
# Copyright (C) 2014, Chef
#

# standalone, tier or ha
default['topology'] = "tier"

default['drbd']['enable'] = false
default['couchdb']['enable'] = false
default['rabbitmq']['enable'] = false
default['postgresql']['enable'] = false
default['oc_bifrost']['enable'] = false
default['opscode_certificate']['enable'] = false
default['opscode_account']['enable'] = false
default['opscode_solr']['enable'] = false
default['opscode_expander']['enable'] = false
default['bookshelf']['enable'] = false
default['opscode_org_creator']['enable'] = false
default['opscode_erchef']['enable'] = false
default['bootstrap']['enable'] = false
default['opscode_webui']['enable'] = false
default['opscode_chef_mover']['enable'] = false
default['nginx']['enable'] = false
default['keepalived']['enable'] = false
