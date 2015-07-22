# -*- mode: ruby -*-
# vi: set ft=ruby :

require './vagrant/provision.rb'

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Require a recent version of vagrant otherwise some have reported errors setting host names on boxes
Vagrant.require_version ">= 1.6.2"

# Determine whether vagrant should use nfs to sync folders
$use_nfs = ENV['VAGRANT_USE_NFS'] == 'true'

# The number of minions to provision
$num_minion = 2

# ip configuration
$master_ip       = "10.246.2.125"
$minion_ip_base  = "10.246.2."
$minion_ips      = $num_minion.times.collect { |n| $minion_ip_base + "#{n+2}" }
$minion_ips_str  = $minion_ips.join(",")

##################################################
# Main
##################################################

# Give access to all physical cpu cores
host = RbConfig::CONFIG['host_os']
if host =~ /darwin/
  $vm_cpus = `sysctl -n hw.physicalcpu`.to_i
elsif host =~ /linux/
  $vm_cpus = `cat /proc/cpuinfo | grep 'core id' | sort -u | wc -l`.to_i
  if $vm_cpus < 1
      $vm_cpus = `nproc`.to_i
  end
else
  $vm_cpus = 2
end

# Give VM 512MB of RAM 
$vm_mem = 2048

################
# Main
################
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-vbguest") then
    config.vbguest.auto_update = false
  end

  def configure(host, hostname, ip)
    host.vm.box     = "ubuntu/ubuntu-15.04-amd64"
    host.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/vivid/current/vivid-server-cloudimg-amd64-vagrant-disk1.box"

    host.vm.synced_folder ".", "/vagrant", nfs: $use_nfs

    host.vm.provider :virtualbox do |v|
      v.customize ["modifyvm", :id, "--memory", $vm_mem]
      v.customize ["modifyvm", :id, "--cpus", $vm_cpus]

      # Use faster paravirtualized networking
      v.customize ["modifyvm", :id, "--nictype1", "virtio"]
      v.customize ["modifyvm", :id, "--nictype2", "virtio"]
    end
  end

  ################
  # Master
  ################
	config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: $master_ip

    configure(master, "master", $master_ip)
    provision(master, "master", $master_ip)

	  master.vm.provision "shell", inline: "/vagrant/vagrant/provision-master.sh #{$master_ip}"
	end

  ################
  # Minions
  ################
  $num_minion.times do |n|
    config.vm.define "minion-#{n+1}" do |minion|
      minion_index = n+1
      minion_ip    = $minion_ips[n]
      minion.vm.hostname = "minion-#{minion_index}"
      minion.vm.network "private_network", ip: "#{minion_ip}"
      
      configure(minion, "minion-#{minion_index}", "#{minion_ip}")
      provision(minion, "minion-#{minion_index}", "#{minion_ip}")

      minion.vm.provision "shell", inline: "/vagrant/vagrant/provision-minion.sh #{minion_index} #{minion_ip} #{$num_minion} #{$master_ip}"
    end
  end

end

