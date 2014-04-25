if platform_family?('debian')
  file '/etc/apt/sources.list.d/enterprise-chef.list' do
    content "deb http://10.227.62.73 precise main\n"
  end

  execute 'apt-get update'
end
