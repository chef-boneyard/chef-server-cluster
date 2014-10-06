# oc-ec

## Requirements

This particular iteration of the cookbook is very much "works on my machine" at the moment. To mimic the environment, there's a few steps to take. This assumes a `chef-repo` is used and the oc-ec cookbook is being used locally (e.g., berks installed into a vendor path, or a symlink to the cookbook's repository).

#### Configure ~/.aws/config with default credentials

Specify the aws access and secret access keys for the IAM user that should be launching the instances. Specify the region to use. In the Chef AWS account, I was using the us-west-2 (Oregon) region.

```text
[default]
aws_access_key_id=ACCESS-KEY
aws_secret_access_key=SECRET-ACCESS-KEY
region=us-west-2
```

#### Start up Chef Zero on port 7799

There's a bug in chef-client's local mode, and I never narrowed it down. Running chef-zero separately worked. Alternatively one could use regular Chef Server like Hosted Chef or opsmaster.

```
chef-zero -l debug -p 7799
```

#### Create a .chef/knife.rb

I used `hc-metal-provisioner` as the name of the SSH key pair. It's likely this won't match what you're using, as I have the private key for this and you don't.

```ruby
config_dir = File.dirname(__FILE__)
chef_server_url 'http://localhost:7799'
node_name        'metal-provisioner'
cookbook_path [File.join(config_dir, '..', 'cookbooks')]
private_keys 'hc-metal-provisioner' => '/tmp/ssh/id_rsa'
public_keys  'hc-metal-provisioner' => '/tmp/ssh/id_rsa.pub'
```

Change the Chef Server URL if a different server is used instead of Hosted/opsmaster.

#### Create a topology data bag item

TODO: (jtimberman) This may be refactored to an alternative kind of configuration as part of consolidating our myriad of "chef server" cookbooks.

```json
{
  "id": "topology",
  "topology": "tier",
  "disabled_svcs": [],
  "enabled_svcs": [],
  "vips": [],
  "dark_launch": {
    "actions": true
  },
  "api_fqdn": "api.chef.sh",
  "notification_email": "ops@chef.io"
}
```

#### Create a secrets data bag and populate it with the SSH keys

For example from above, I'm using an item named `hc-metal-provisioner-chef-aws-us-west-2`. This is hardcoded in the `oc-ec::metal-provision` recipe, but one could edit that or make it an attribute. This will move to a Chef Vault item at some point as noted in the comment in the recipe.

```json
{
  "id": "hc-metal-provisioner-chef-aws-us-west-2",
  "private_ssh_key": "BEGIN RSA KEY blah blah snip",
  "public_ssh_key": "ssh-rsa blah blah blah"
}
```

#### Upload the cookbook and data bag items to the server

```
knife upload data_bags cookbooks
```

Or if using berks (as we should, or policyfiles, at a future date).

```
knife upload data_bags
berks install
berks upload
```

#### Run chef-client on the local system (provisioning node)

```
chef-client -c .chef/knife.rb -o oc-ec::metal-provision
```

### Platform:

64 bit Ubuntu 14.04

## Attributes

## Recipes

default - The only recipe needed, sets up EC

## Testing

The cookbook provides the following Rake tasks for testing:

    rake foodcritic                   # Lint Chef cookbooks
    rake integration                  # Alias for kitchen:all
    rake kitchen:all                  # Run all test instances
    rake kitchen:default-ubuntu-1204  # Run default-ubuntu-1204 test instance
    rake rubocop                      # Run RuboCop style and lint checks
    rake spec                         # Run ChefSpec examples
    rake test                         # Run all tests

## License and Author

- Author: Paul Mooring <paul@getchef.com>
- Author: Joshua Timberman <joshua@getchef.com>
- Copyright (C) 2014 Chef Software, Inc. <legal@getchef.com>

All rights reserved.
