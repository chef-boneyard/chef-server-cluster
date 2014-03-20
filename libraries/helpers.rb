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

  def self.ec_vars(attrs)
    ec_vars = {}
    ec_vars[:enabled_svcs]  = []
    ec_vars[:disabled_svcs] = []
    ec_vars[:vips]          = []
    ec_vars[:bootstrap]     = attrs['bootstrap']

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
      if attrs[svc]['enable']
        ec_vars[:enabled_svcs] << svc
        ec_vars[:vips] << svc unless OTHER_SVCS.include?(svc)
      else
        ec_vars[:disabled_svcs] << svc
      end
    end

    if backend?(ec_vars[:enabled_svcs])
      ec_vars[:role] = 'backend'
    elsif frontend?(ec_vars[:enabled_svcs])
      ec_vars[:role] = 'frontend'
    end

    ec_vars
  end

  def self.backend?(enabled_svcs)
    (enabled_svcs & BACKEND_SVCS).length > 0
  end

  def self.frontend?(enabled_svcs)
    (enabled_svcs & FRONTEND_SVCS).length > 0
  end
end
