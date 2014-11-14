# chef-server-cluster

Manage Chef Server clusters with Chef, using chef-provisioning in a provisioning recipe that can run from a local machine, or a provisioning instance.

**NOTE** THERE BE DRAGONS HERE.

## TODO: This is still an MVP, but work will continue to improve it over time.

This cookbook reflects CHEF's operations team's opinions on building a scalable Chef Server. It also reflects the team decisions on which platform to use, and the best approaches we think work for running Hosted Chef. It may or may not work on other infrastructures, with or without modification. While it is an open source project, we're taking contributions only under careful consideration. Over time we intend this to be *the* cookbook for managing a (clustered) Chef Server. As it is a pre-1.0 release, don't be surprised if things break in wildly fantastic ways between point/patch releases.

## Requirements

There's a few steps to take to get the provisioning node ready to launch the cluster. This assumes a `chef-repo` is used and the cookbook is being used locally (e.g., berks installed into a vendor path, or a symlink to the cookbook's repository). These instructions are probably incomplete, but we'll improve them over time.

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

#### Create a .chef/knife.rb

I used `hc-metal-provisioner` as the name of the SSH key pair. It's likely this won't match what you're using, as I have the private key for this and you don't.

```ruby
config_dir = File.dirname(__FILE__)
chef_server_url 'http://localhost:7799'
node_name        'chef-provisioner'
cookbook_path [File.join(config_dir, '..', 'cookbooks')]
private_keys 'hc-metal-provisioner' => '/tmp/ssh/id_rsa'
public_keys  'hc-metal-provisioner' => '/tmp/ssh/id_rsa.pub'
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

For example from above, I'm using an item named `hc-metal-provisioner-chef-aws-us-west-2`. This is hardcoded in the `chef-server-cluster::cluster-provision` recipe, but one could edit that or make it an attribute. This will move to a Chef Vault item at some point as noted in the comment in the recipe.

```json
{
  "id": "hc-metal-provisioner-chef-aws-us-west-2",
  "private_ssh_key": "BEGIN RSA KEY blah blah snip",
  "public_ssh_key": "ssh-rsa blah blah blah"
}
```

Be sure the string values are a single line.

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

Other platforms will be added in the future according to the platforms that CHEF supports for Chef Server 12.

### Cookbooks:

* [chef-server-ingredient](https://github.com/opscode-cookbooks/chef-server-ingredient): manages chef server components/addons and more.
* [chef-vault](https://supermarket.getchef.com/cookbooks/chef-vault): required for secrets management (future plans)

## Attributes

See `attributes/default.rb` for default values. Here's how this cookbook's attributes (`node['chef-server-cluster']`) work and/or affect behavior.

* `topology`: configures the top-level topology in `/etc/opscode/chef-server.rb`
* `role`: sets the role for the specific node, affects how configuration is rendered in `/etc/opscode/chef-server.rb`.
* `bootstrap['enable']`: whether bootstrapping Chef Server should be done. This triggers whether the configuration in `/etc/opscode/chef-server.rb` will run the bootstrap recipes. This should only be enabled on the first `backend` node in the cluster.
* `aws`: A configuration hash for Amazon Web Services EC2, used by the chef-provisioning recipes to launch instances.
* `aws['region']`: sets the region where the instances should be launched. The default is `us-west-2` because that's where CHEF's operations team is building the new infrastructure.
* `aws['machine_options']`: this is a hash passed directly into the Chef Provisioning recipe DSL method, `with_machine_options`. If overriding these attributes, you probably want:

```ruby
node['chef-server-cluster']['aws']['machine_options']['ssh_username']
node['chef-server-cluster']['aws']['machine_options']['bootstrap_options']['key_name']
node['chef-server-cluster']['aws']['machine_options']['bootstrap_options']['image_id']
```

* `ssh_username`: The default user on the AMI used, e.g. `ubuntu` or `root` (platform/AMI specific)
* `key_name`: The name of the AWS SSH keypair.
* `image_id`: The AMI to use. This must be changed per-region if `node['chef-server-cluster']['aws']['region']` is changed.

## Recipes

These may change wildly as we develop the cookbook. The intention behind the current recipes is:

* analytics.rb: stands up a Chef Analytics server.
* bootstrap.rb: the initial backend node in a cluster, should be the first node created. Other backend nodes may have a dedicated `backend` recipe they use. Or not.
* default.rb: manage the common resources required by backend and frontend systems.
* frontend.rb: stands up a front end system.
* load-secrets.rb: loads secrets from a data bag (chef-vault). This is incomplete and non-functional at this time.
* cluster-clean.rb: cleans up all the instances. Don't use against a live running cluster! **This is provided for testing purposes only!! It will destroy all the cluster's data!**
* cluster-provision.rb: performs the provisioning of the instances in the cluster. In the future it will be more dynamic through the use of the topology data bag item.
* setup-provisioner.rb: common options for "clean" and "provision" are initialized here.
* save-secrets.rb: saves secrets to a data bag (chef-vault). This is incomplete and non-functional at this time.
* standalone.rb: stands up a standalone single Chef Server.

## Documentation

This README serves as the only documentation for the cookbook at this time.

Chef Server documentation:

http://docs.getchef.com/server/

Chef Server configuration settings:

https://docs.getchef.com/config_rb_chef_server_optional_settings.html

## License and Author

- Author: Paul Mooring <paul@getchef.com>
- Author: Joshua Timberman <joshua@getchef.com>
- Copyright (C) 2014 Chef Software, Inc. <legal@getchef.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
