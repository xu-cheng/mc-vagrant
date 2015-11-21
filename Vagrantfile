# vim: set ft=ruby:

require "yaml"
$config = YAML.load File.read(File.expand_path "#{File.dirname(__FILE__)}/config.yml")

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.hostname = $config["digital_ocean"]["hostname"]

  config.vm.provider :digital_ocean do |provider, override|
    override.ssh.private_key_path = "~/.ssh/id_rsa"
    override.vm.box = "digital_ocean"
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"

    provider.token = ENV["DIGITAL_OCEAN_TOKEN"]
    provider.image = "centos-7-0-x64"
    provider.region = $config["digital_ocean"]["region"]
    provider.size = $config["digital_ocean"]["size"]
    provider.ipv6 = $config["digital_ocean"]["ipv6"]
    provider.private_networking = $config["digital_ocean"]["private_networking"]
    provider.ssh_key_name = $config["digital_ocean"]["ssh_key_name"]
  end

  config.vm.provision :shell, path: "bootstrap.sh", args: [$config["minecraft"]["op_id"]]
end
