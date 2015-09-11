# chef-server-cluster

Manage Chef Server clusters with Chef, using chef-provisioning in a provisioning recipe that can run from a local machine, or a provisioning instance.

**NOTE** THERE BE DRAGONS HERE.

## TODO: This is still an MVP, but work will continue to improve it over time.

This cookbook reflects CHEF's operations team's opinions on building a scalable Chef Server. It also reflects the team decisions on which platform to use, and the best approaches we think work for running Hosted Chef. It may or may not work on other infrastructures, with or without modification. While it is an open source project, we're taking contributions only under careful consideration. Over time we intend this to be *the* cookbook for managing a (clustered) Chef Server. As it is a pre-1.0 release, don't be surprised if things break in wildly fantastic ways between point/patch releases.

## Requirements

There's a few steps to take to get the provisioning node ready to launch the cluster. This assumes a `chef-repo` is used and the cookbook is being used locally (e.g., berks installed into a vendor path, or a symlink to the cookbook's repository).

It is assumed that these steps are done in the `chef-repo`.

#### Configure ~/.aws/config with default credentials

Specify the aws access and secret access keys for the IAM user that should be launching the instances. Specify the region to use. In the Chef AWS account, I was using the us-west-2 (Oregon) region.

```text
[default]
aws_access_key_id=ACCESS-KEY
aws_secret_access_key=SECRET-ACCESS-KEY
region=us-west-2
```

#### Start up Chef Zero on port 7799

There's a bug in chef-client's local mode, and I never narrowed it down. Running chef-zero separately worked. Alternatively one could use regular Chef Server like Hosted Chef.

```
chef-zero -l debug -p 7799
```

#### Create a .chef/config.rb

I used `hc-metal-provisioner` as the name of the SSH key pair. It's likely this won't match what you're using, as I have the private key for this and you don't.

```ruby
config_dir = File.dirname(__FILE__)
chef_server_url 'http://localhost:7799'
node_name        'chef-provisioner'
cookbook_path [File.join(config_dir, '..', 'cookbooks')]
```

Change the `chef_server_url` and `node_name` as appropriate if using another Chef Server.

#### Create a topology data bag item

TODO: (jtimberman) This may be refactored to an alternative kind of configuration as part of consolidating our "chef server" cookbooks.

This data bag item informs configuration options that (may) need to be present in `/etc/opscode/chef-server.rb`.

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
  "notification_email": "ops@getchef.com"
}
```

#### Create a secrets data bag and populate it with the SSH keys

For example from above, I'm using an item named `hc-metal-provisioner-chef-aws-us-west-2` from the attribute `node['chef-server-cluster']['chef-provisioner-key-name']`. This is not the same name as the actual SSH key in the AWS account I'm using, it's namespaced for the data bag.

```json
{
  "id": "hc-metal-provisioner-chef-aws-us-west-2",
  "private_ssh_key": "BEGIN RSA KEY blah blah snip",
  "public_ssh_key": "ssh-rsa blah blah blah"
}
```

Be sure the string values are a single line, replacing actual newlines in the files with `\n`.

#### Create a "private-chef-secrets" data bag item

Create `data_bags/secrets/private-chef-secrets-_default.json` data bag item with the following content. While `_default` won't be the environment used in "real environments" it is fine for the MVP for minimal configuration required.

```json
{
  "id": "private-chef-secrets-_default",
  "data": {
    "rabbitmq": {
      "password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512",
      "jobs_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512",
      "actions_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512"
    },
    "postgresql": {
      "sql_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512",
      "sql_ro_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512"
    },
    "oc_id": {
      "sql_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512",
      "secret_key_base": "SOMETHINGRANDOMLYAWESOMELIKEASHA512"
    },
    "drbd": {
      "shared_secret": "THISISSHORTERTHANTHEOTHERSRANDOMLYGENERATED"
    },
    "keepalived": {
      "vrrp_instance_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512"
    },
    "oc_bifrost": {
      "superuser_id": "SOMETHINGTHIRTYTWOCHARACTERS",
      "sql_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512",
      "sql_ro_password": "SOMETHINGRANDOMLYAWESOMELIKEASHA512"
    },
    "bookshelf": {
      "access_key_id": "SOMETHINGTHIRTYTWOCHARACTERS",
      "secret_access_key": "SOMETHINGRANDOMLYAWESOMELIKEASHA512"
    }
  }
}
```

#### Create a "opscode-reporting-secrets-_default.json" data bag item

These are required for Chef Reporting and Chef Analytics to work properly. Each secret should be the specified number of characters due to the database schema.

```json
{
  "id": "opscode-reporting-secrets-_default",
  "data": {
    "postgresql": {
      "sql_password": "One-hundred characters",
      "sql_ro_password": "One-hundred characters"
    },
    "opscode_reporting": {
      "rabbitmq_password": "One-hundred characters"
    }
  }
}
```

#### Upload the cookbook and data bag items to the server

```
knife upload data_bags cookbooks
```

Or if using berks (or policyfiles, at a future date).

```
knife upload data_bags
berks install
berks upload
```

#### Run chef-client on the local system (provisioning node)

```
chef-client -c .chef/knife.rb -o chef-server-cluster::cluster-provision
```

The outcome should be:

1. Frontend
2. Backend
3. Analytics

Navigate to https://frontend-fqdn and sign up!

### Platform:

64 bit Ubuntu 14.04

Other platforms may be added in the future according to the platforms that CHEF supports for Chef Server 12.

### Cookbooks:

* [chef-server-ingredient](https://github.com/chef-cookbooks/chef-server-ingredient): manages chef server components/addons and more.
* [chef-vault](https://supermarket.getchef.com/cookbooks/chef-vault): required for secrets management (future plans)

## Attributes

See `attributes/default.rb` for default values. Here's how this cookbook's attributes (`node['chef-server-cluster']`) work and/or affect behavior.

Attribute             | Description |Type | Default
----------------------|-------------|-----|--------
`topology`            | Configures the top-level topology in `/etc/opscode/chef-server.rb` | String | 'tier'
`role`                | Sets the role for the specific node, affects how configuration is rendered in `/etc/opscode/chef-server.rb` | String | 'frontend'
`bootstrap['enable']` | whether bootstrapping Chef Server should be done. This triggers whether the configuration in `/etc/opscode/chef-server.rb` will run the bootstrap recipes. This should only be enabled on the first `backend` node in the cluster. | Boolean | false
`driver`              | A configuration hash for the chef-provisioning driver | Hash | See below
`driver['gems']`      | An Array of Hashes that specify the gem name and the library to require, used to specify alternative chef-provisioning drivers and load them | Array of Hashes | [{'name' => 'chef-provisioning-aws', 'require' => 'chef/provisioning/aws_driver'}]
`driver['with-parameter']`  | The parameter passed to the `with_driver` chef-provisioning Recipe DSL method used as the URI for the driver connection. | String | 'aws::us-west-2'
`driver['machine_options']` | This is a hash passed directly into the Chef Provisioning recipe DSL method, `with_machine_options`. See below for further explanation | Hash | See `attributes/default.rb`.

This cookbook is designed primarily to be used with AWS as that is our use case. However, by modifying the various `driver` attributes, other providers may be usable. This is unsupported, and may require additional configuration consideration.

The `driver['with-parameter']` attribute will get passed to chef-provisioning's `with_driver` Recipe DSL method directly. Depending on what driver is used, the `driver['gems']` attribute may need to be changed to install and require another driver. For example in a recipe:

```ruby
node.default['chef-server-cluster']['driver']['gems'] = [{
  'name' => 'chef-provisioning-fog',
  'require' => 'chef/provisioning/fog_driver'
}]
```

In the `setup-provisioner` recipe, this will install `chef-provisioning-fog` with `chef_gem`, and then require the library `chef/provisioning/fog_driver` to make it usable for the `with_driver` and `with_machine_options` methods, which can then be used for creating instances with the new driver in the machine resources in the `cluster-provision` recipe.

You'll need to consult the chef-provisioning driver documentation for the various options that can be used for `with_machine_options`. If you're using AWS and simply want to customize for your local environment, change these:

```ruby
node.default['chef-server-cluster']['driver']['machine_options']['ssh_username'] = 'not-ubuntu'
node.default['chef-server-cluster']['driver']['machine_options']['bootstrap_options']['key_name'] = 'mykey-by-region'
node.default['chef-server-cluster']['driver']['machine_options']['bootstrap_options']['image_id'] = 'ami-12345678'
node.default['chef-server-cluster']['driver']['machine_options']['bootstrap_options']['instance_type'] = 'm1.small'
```

* `ssh_username`: The default user on the AMI used, e.g. `ubuntu` or `root` (platform/AMI specific)
* `key_name`: The name of the **unique** AWS SSH keypair. See the `setup-ssh-keys.rb` recipe description below for special considerations.
* `image_id`: The AMI to use. This must be changed per-region if the region in `node['chef-server-cluster']['driver']['with-parameter']` is changed.
* `instance_type`: Formerly `flavor_id`, this is the EC2 instance size on AWS.

## Recipes

These may change wildly as we develop the cookbook. The intention behind the current recipes is:

* analytics.rb: stands up a [Chef Analytics](http://docs.chef.io/analytics) server in [standalone mode](http://docs.chef.io/analytics/install_analytics.html#standalone-version-1-1).
* [bootstrap.rb](https://github.com/chef-cookbooks/chef-server-cluster/issues/30): the initial backend node in a cluster, should be the first node created.
* cluster-clean.rb: cleans up all the instances. Don't use against a live running cluster! **This is provided for testing purposes only!! It will destroy all the cluster's data!**
* cluster-provision.rb: performs the provisioning of the instances in the cluster.
* default.rb: manage the common resources required by backend and frontend systems.
* frontend.rb: stands up a front end system.
* load-secrets.rb: loads secrets from a data bag (chef-vault). This is incomplete and non-functional at this time.
* save-secrets.rb: saves secrets to a data bag (chef-vault). This is incomplete and non-functional at this time.
* setup-provisioner.rb: Installs the gems and for the chef-provisioning driver, and then requires the library. Does this during compile time specifically because the require must happen for recipe DSL methods provided by chef-provisioning.
* setup-ssh-keys.rb: **Important** To attempt to be driver-agnostic, we rely on chef-provisioning's implicit configuration of SSH keys. You need to create your key ahead of time, and store it in a data bag item as described above. The `node['chef-server-cluster']['driver']['machine_options']['key_name']` key will be used. The content from the data bag item will be written to `~/.ssh/key_name` and `~/.ssh/key_name.pub` for the private and public keys respectively. Make sure your key name is unique!

## Documentation

This README serves as the only documentation for the cookbook at this time.

Chef Server documentation:

* https://docs.chef.io/server/

Chef Server configuration settings:

* http://docs.chef.io/open_source/config_rb_chef_server_optional_settings.html

## Issues

Please report issues in this repository. Please also understand that this cookbook is intended to be narrow and opinionated in scope, and may not work for all use cases.

* https://github.com/chef-cookbooks/chef-server-cluster/issues

## License and Author

- Author: Paul Mooring <paul@chef.io>
- Author: Joshua Timberman <joshua@chef.io>
- Copyright (C) 2014-2015 Chef Software, Inc. <legal@chef.io>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
