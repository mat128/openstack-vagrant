# Vagrant OpenStack Cloud Provider
[![Build Status](https://travis-ci.org/mat128/vagrant-openstack.png?branch=master)](https://travis-ci.org/mat128/vagrant-openstack)

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
$ git clone https://github.com/mat128/vagrant-openstack.git
$ cd vagrant-openstack
$ gem build vagrant-openstack.gemspec
$ vagrant plugin install vagrant-openstack-*.gem
...
$ vagrant up --provider=openstack
...
```

Of course prior to doing this, you'll need to obtain an OpenStack-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to actually use a dummy OpenStack box and specify all the details
manually within a `config.vm.provider` block. So first, add the dummy
box using any name you want:

```
$ vagrant box add dummy https://github.com/mat128/vagrant-openstack/raw/master/dummy.box
...
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```
require 'vagrant-openstack'

Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.vm.provider :openstack do |os|    # e.g.
    os.username = "YOUR USERNAME"          # "#{ENV['OS_USERNAME']}"
    os.api_key  = "YOUR API KEY"           # "#{ENV['OS_PASSWORD']}" 
    os.flavor   = /m1.tiny/
    os.image    = /Ubuntu/
    os.endpoint = "KEYSTONE AUTH URL"      # "#{ENV['OS_AUTH_URL']}/tokens"  
    os.keypair_name = "YOUR KEYPAIR NAME"
    os.ssh_username = "SSH USERNAME"
    os.public_network_name = "NAME OF THE PUBLIC NETWORK"
    os.networks = %w(net1 net2 net3)
    os.tenant = "NAME OF THE TENANT"
  end
end
```

And then run `vagrant up --provider=openstack`.

This will start a tiny Ubuntu instance in your OpenStack installation within
your tenant. And assuming your SSH information was filled in properly
within your Vagrantfile, SSH and provisioning will work as well.

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `openstack` boxes. You can view an example box in
the [example_box/ directory](https://github.com/cloudbau/vagrant-openstack/tree/master/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

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

To work on the `vagrant-openstack` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

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
