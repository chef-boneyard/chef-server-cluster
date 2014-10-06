#
# Cookbook Name:: oc-ec
# Attributes:: default
#
# Copyright (C) 2014, Chef Software, Inc. <legal@getchef.com>
#
default['ec']['topology'] = 'tier'
default['ec']['role'] = 'standalone'
default['ec']['bootstrap']['enable'] = false
