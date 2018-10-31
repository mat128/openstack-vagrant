# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-openstack-cloud-provider/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-openstack-cloud-provider"
  gem.version       = VagrantPlugins::OpenStack::VERSION
  gem.licenses      = ['MIT']
  gem.authors       = ["Mathieu Mitchell"]
  gem.email         = ["mat128@gmail.com"]
  gem.description   = "Vagrant provider for OpenStack clouds."
  gem.summary       = "Enables Vagrant to manage machines in OpenStack Cloud."
  gem.homepage      = "http://www.vagrantup.com"

  gem.add_runtime_dependency "fog-openstack", "~> 0.1.26"
  gem.add_runtime_dependency "promise", "~> 0.3.1"

  gem.add_development_dependency "rake", '< 11.0'
  gem.add_development_dependency "rspec", "~> 3.5.0"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
