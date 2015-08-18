# -*- mode: ruby -*-
# vi: set ft=ruby :

require './vagrant/provision.rb'
require './vagrant/swarm.rb'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Require a recent version of vagrant otherwise some have reported errors setting host names on boxes
Vagrant.require_version ">= 1.6.2"

# Determine whether vagrant should use nfs to sync folders
$use_nfs = ENV['VAGRANT_USE_NFS'] == 'true'

# The number of minions to provision
$num_minion = 3

# ip configuration
$minion_ip_base  = "10.246.2."
$minion_ips      = $num_minion.times.collect { |n| $minion_ip_base + "#{n+2}" }
$minion_ips_str  = $minion_ips.join(",")

$swarm_token     = create_swarm()

##################################################
# Main
##################################################

################
# Main
################
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  ################
  # Minions
  ################
  $num_minion.times do |minion_index|
    config.vm.define "minion-#{minion_index}" do |minion|
      minion_ip          = $minion_ips[minion_index]
      minion.vm.hostname = "minion-#{minion_index}"
      minion.vm.network "private_network", ip: "#{minion_ip}"
      
      configure(minion, "minion-#{minion_index}", "#{minion_ip}")
      provision(minion, "minion-#{minion_index}", "#{minion_ip}")

      minion.vm.provision "shell", inline: "/vagrant/vagrant/provision-minion.sh #{minion_index} #{minion_ip} #{$num_minion} #{$swarm_token}"
    end
  end

end

