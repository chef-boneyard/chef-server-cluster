#
# Cookbook Name:: oc-ec
# Attributes:: default
#
# Copyright (C) 2014, Chef
#

# standalone, tier or ha
default['ec']['topology'] = "tier"

default['ec']['drbd']['enable'] = false
default['ec']['couchdb']['enable'] = false
default['ec']['rabbitmq']['enable'] = false
default['ec']['postgresql']['enable'] = false
default['ec']['oc_bifrost']['enable'] = false
default['ec']['opscode_certificate']['enable'] = false
default['ec']['opscode_account']['enable'] = false
default['ec']['opscode_solr']['enable'] = false
default['ec']['opscode_expander']['enable'] = false
default['ec']['bookshelf']['enable'] = false
default['ec']['opscode_org_creator']['enable'] = false
default['ec']['opscode_erchef']['enable'] = false
default['ec']['bootstrap']['enable'] = false
default['ec']['opscode_webui']['enable'] = false
default['ec']['opscode_chef_mover']['enable'] = false
default['ec']['nginx']['enable'] = false
default['ec']['keepalived']['enable'] = false
