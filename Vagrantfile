# vim: set ft=ruby:

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"

  config.vm.provider :digital_ocean do |provider, override|
    override.ssh.private_key_path = "~/.ssh/id_rsa"
    override.vm.box = "digital_ocean"
    override.vm.box_url = "https://github.com/smdahlen/vagrant-digitalocean/raw/master/box/digital_ocean.box"

    provider.name = "mc.xuc.me"
    provider.token = ENV["DIGITAL_OCEAN_TOKEN"]
    provider.image = "centos-7-0-x64"
    provider.region = "sgp1"
    provider.size = "1gb"
    provider.ipv6 = true
    provider.ssh_key_name = "Personal SSH Key"
  end

  config.vm.provision :shell, path: "bootstrap.sh"
end
