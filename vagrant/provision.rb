def provision(host, hostname, ip)
  pkgs = "aufs-tools ethtool daemon curl"

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

