# Vagrant OpenStack Cloud Provider
[![Build Status](https://travis-ci.org/mat128/vagrant-openstack-cloud-provider.png?branch=master)](https://travis-ci.org/mat128/vagrant-openstack-cloud-provider)

This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an
[OpenStack Cloud](http://www.openstack.org) provider to Vagrant,
allowing Vagrant to control and provision machines within an OpenStack
cloud.

This plugin started as a fork of the Vagrant Rackspace provider.

**Note:** This plugin requires Vagrant 1.2+. The last version of this plugin supporting Vagrant 1.1 is 0.3.0.

## Features

* Boot OpenStack Cloud instances.
* SSH into the instances.
* Provision the instances with any built-in Vagrant provisioner.
* Minimal synced folder support via `rsync`.
* Create instances with a specific list of networks

## Usage

```
$ vagrant plugin install vagrant-openstack-cloud-provider
$ vagrant box add dummy https://github.com/mat128/vagrant-openstack-cloud-provider/raw/master/dummy.box
$ cat <<EOF > Vagrantfile
require 'vagrant-openstack-cloud-provider'

Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.vm.provider :openstack do |os|
    os.username = "#{ENV['OS_USERNAME']}"
    os.api_key  = "#{ENV['OS_PASSWORD']}"
    os.flavor   = /m1.tiny/
    os.image    = /Ubuntu/
    os.endpoint = "#{ENV['OS_AUTH_URL']}/tokens"
    os.keypair_name = "" # Your keypair name
    os.ssh_username = "" # Your image SSH username
    os.public_network_name = "" # Your Neutron network name
    os.networks = %w(net1 net2 net3) # Additional neutron networks
    os.tenant = "#{ENV['OS_TENANT_NAME'}"
    os.region = "" # Region name, if necessary
  end
end 
$ vagrant up --provider=openstack
...
```

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `api_key` - The API key for accessing OpenStack.
* `flavor` - The server flavor to boot. This can be a string matching
  the exact ID or name of the server, or this can be a regular expression
  to partially match some server flavor.
* `image` - The server image to boot. This can be a string matching the
  exact ID or name of the image, or this can be a regular expression to
  partially match some image.
* `endpoint` - The keystone authentication URL of your OpenStack installation.
* `server_name` - The name of the server within the OpenStack Cloud. This
  defaults to the name of the Vagrant machine (via `config.vm.define`), but
  can be overridden with this.
* `username` - The username with which to access OpenStack.
* `keypair_name` - The name of the keypair to access the machine.
* `ssh_username` - The username to access the machine.
* `public_network_name` - The name of the public network within your Openstack cluster
* `networks` - A list -- use %w(net1 net2) -- of networks to configure
  on your instance.
* `tenant` - The name of the tenant on which the virtual machine should spawn.

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :openstack do |os|
    os.username = "mitchellh"
    os.api_key  = "foobarbaz"
  end
end
```

## Networks

Networking features in the form of `config.vm.network` are not
supported with `vagrant-openstack`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the OpenStack server.

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the OpenStack provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

This is good enough for all built-in Vagrant provisioners (shell,
chef, and puppet) to work!

## Development

To work on the `vagrant-openstack-cloud-provider` plugin, clone this
repository out, and use [Bundler](http://gembundler.com) to get the
dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
that uses it, and uses bundler to execute Vagrant:

```
$ bundle exec vagrant up --provider=openstack
```
