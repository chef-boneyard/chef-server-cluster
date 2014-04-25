#
# Cookbook Name:: oc-ec
# Libraries:: helpers
#
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#

module ChefHelpers
  BACKEND_SVCS = [
    'drbd',
    'couchdb',
    'rabbitmq',
    'postgresql',
    'opscode_expander',
    'opscode_solr'
  ] unless defined?(BACKEND_SVCS)

  FRONTEND_SVCS = [
    'nginx',
    'oc_bifrost',
    'opscode_account',
    'opscode_certificate',
    'opscode_erchef'
  ] unless defined?(FRONTEND_SVCS)

  OTHER_SVCS = [
    'opscode_expander',
    'bookshelf',
    'opscode_org_creator',
    'opscode_chef_mover'
  ] unless defined?(OTHER_SVCS)

  VIP_SVCS = [
    'bookshelf',
    'opscode_solr',
    'opscode_erchef',
    'nginx',
    'postgesql',
    'rabbitmq'
  ] unless defined?(VIP_SVCS)

  def self.ec_vars(node)
    ec_vars = {}
    ec_vars[:enabled_svcs]  = []
    ec_vars[:disabled_svcs] = []
    ec_vars[:vips]          = {}
    # the bootstrap attribute is used on the initial node that sets up all the
    # secrets required by other nodes.
    ec_vars[:bootstrap]     = node['ec']['bootstrap']

    [
      'drbd',
      'couchdb',
      'rabbitmq',
      'postgresql',
      'oc_bifrost',
      'opscode_certificate',
      'opscode_account',
      'opscode_solr',
      'opscode_expander',
      'opscode_org_creator',
      'opscode_chef_mover',
      'bookshelf',
      'opscode_erchef',
      'opscode_webui',
      'nginx',
      'keepalived'
    ].each do |svc|
      if node['ec'].attribute?(svc) && node['ec'][svc]['enable']
        ec_vars[:enabled_svcs] << svc
        ec_vars[:vips][svc] = find_vip_for_service(svc, node) if VIP_SVCS.include?(svc)
      else
        ec_vars[:disabled_svcs] << svc
      end
    end

    Chef::Log.debug("Enabled services: #{ec_vars[:enabled_svcs].inspect}")
    Chef::Log.debug("Disabled services: #{ec_vars[:disabled_svcs].inspect}")

    if backend?(ec_vars[:enabled_svcs])
      ec_vars[:role] = 'backend'
    elsif frontend?(ec_vars[:enabled_svcs])
      ec_vars[:role] = 'frontend'
    end

    Chef::Log.debug("I'm a #{ec_vars[:role]}")
    ec_vars
  end

  def self.find_vip_for_service(service, node)
    query_components = [
      "ec_#{service}_enable:true",
      "chef_environment:#{node.chef_environment}"
    ]

    Chef::Log.debug("looking for #{service} VIP on #{node.name}")
    results = Chef::Search::Query.new.search(:node, query_components.join(' AND ')).first
    # if we don't get any results for what we wanted, assume this
    # node. Future Chef runs can sort this out later.
    if results.nil? || results.empty?
      vip_node = node
    else
      vip_node = results.first
    end

    Chef::Log.debug("vip node is #{vip_node.inspect}")
    vip_node['ec'][service]['vip'] || vip_node['ipaddress']
  end

  def self.secret_files
    %w{pivotal.cert  pivotal.pem  webui_priv.pem  webui_pub.pem  worker-private.pem  worker-public.pem}
  end

  private

  def self.backend?(enabled_svcs)
    (enabled_svcs & BACKEND_SVCS).empty?
  end

  def self.frontend?(enabled_svcs)
    (enabled_svcs & FRONTEND_SVCS).empty?
  end

end
