
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

# configure a machine
def configure(host, hostname, ip)
	host.vm.box     = "ubuntu/ubuntu-15.04-amd64"
	host.vm.box_url = "https://cloud-images.ubuntu.com/vagrant/vivid/current/vivid-server-cloudimg-amd64-vagrant-disk1.box"

	host.vm.synced_folder ".", "/vagrant", nfs: $use_nfs

	host.vm.provider :virtualbox do |v|
		v.customize ["modifyvm", :id, "--memory", $vm_mem]
		v.customize ["modifyvm", :id, "--cpus",   $vm_cpus]

		# Use faster paravirtualized networking
		v.customize ["modifyvm", :id, "--nictype1", "virtio"]
		v.customize ["modifyvm", :id, "--nictype2", "virtio"]
	end
end

# basic provisioning
def provision(host, hostname, ip)
  pkgs = "aufs-tools ethtool daemon curl ca-certificates"

  # install any extra packages (if needed)
  host.vm.provision :shell, :inline => <<SCRIPT
    for pkg in "#{pkgs}" ; do
      sudo dpkg -l $pkg &>/dev/null
      if [ $? -ne 0 ] ; then
        apt-get install -qq -y --force-yes --no-install-recommends $pkg
      fi
    done
SCRIPT

  # check Docker
  host.vm.provision :shell, :inline => <<SCRIPT
    if [ ! -f /etc/apt/sources.list.d/docker.list ] ; then
      export DEBIAN_FRONTEND=noninteractive
      apt-key adv \
        --keyserver hkp://keyserver.ubuntu.com:80 \
        --recv-keys 36A1D7869245C8950F966E92D8576A8BA88D21E9
      echo 'deb https://get.docker.io/ubuntu docker main' \
        > /etc/apt/sources.list.d/docker.list
      apt-get update
    fi

    # make sure Docker is installed
    sudo dpkg -l lxc-docker &>/dev/null
    if [ $? -ne 0 ] ; then
      apt-get install -qq -y --force-yes --no-install-recommends lxc-docker
      usermod -a -G docker vagrant
      sed -i -e's%-H fd://%-H fd:// -H tcp://0.0.0.0:2375 -s overlay%' /lib/systemd/system/docker.service
      systemctl daemon-reload
      systemctl restart docker
      systemctl enable docker
    fi

    # make sure Docker is running
    systemctl status docker &>/dev/null
    if [ $? -ne 0 ] ; then
      systemctl restart docker
    fi
SCRIPT

  # fix the hostname (if needed)
  host.vm.provision :shell, :inline => <<SCRIPT
    [ "$(hostname)" != "#{hostname}" ] && hostnamectl set-hostname #{hostname} || /bin/true
SCRIPT

end
