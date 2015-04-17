require 'serverspec'

# Required by serverspec
set :backend, :exec

describe command('chef-server-ctl user-list') do
  its(:stdout) { should match /flock/}
end

describe command('chef-server-ctl org-list') do
  its(:stdout) { should match /example/}
end