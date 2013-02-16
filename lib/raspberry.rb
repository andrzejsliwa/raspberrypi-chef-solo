class Raspberry
  def initialize(options)
        @cap          = options.fetch(:capistrano)
        @chef_version = options.fetch(:chef_version)
        @pi           = options.fetch(:pi).to_s
        @logger       = options.fetch(:logger)
        @chef_role    = options.fetch(:chef_role)
  end

  def bootstrap
    @logger.info "Bootstraping Rasberry Pi: #{@pi}"
    apt_upgrade

    [ 'scratch',
      'debian-reference-en dillo idle3 python3-tk idle python-pygame python-tk',
      'lightdm gnome-themes-standard gnome-icon-theme raspberrypi-artwork',
      'gvfs-backends gvfs-fuse desktop-base lxpolkit netsurf-gtk zenity xdg-utils',
      'mupdf gtk2-engines alsa-utils  lxde lxtask menu-xdg gksu',
      'midori xserver-xorg xinit xserver-xorg-video-fbdev',
      'libraspberrypi-dev libraspberrypi-doc',
      'dbus-x11 libx11-6 libx11-data libx11-xcb1 x11-common x11-utils',
      'lxde-icon-theme gconf-service gconf2-common'
    ].each do |pkgs|
      apt_remove(pkgs)
    end

    [ 'build-essential git-core',
      'ruby1.9.3 ruby1.9.1-dev libopenssl-ruby libxml2-dev libxslt-dev',
      'htop mc',
    ].each do |pkgs|
      apt_install(pkgs)
    end

    gem_install "chef --version=#{@chef_version}"
    gem_install 'bundler'
    sudo_run %{sh -c "echo 'PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/lib/gems/1.8/bin\"' > /etc/environment"%}

    upload_key
    @logger.info "Bootstraping Done."
  end

  def provision
    tmp_provision = '/tmp/provision'
    run %{test -d "#{tmp_provision}"
          && (cd #{tmp_provision} && git checkout chef/Cheffile.lock && git pull; git checkout origin/master)
          || git clone #{@cap.repository} #{tmp_provision}
          && cd #{tmp_provision} && git checkout origin/master}
    sudo_run %{sh -c "cd #{tmp_provision} && bundle install"}
    sudo_run %{sh -c "cd #{tmp_provision}/chef && bundle exec librarian-chef install"}
    sudo_run %{chef-solo -c #{tmp_provision}/chef/solo.rb -o "role[#{@chef_role}]"}
  end

  def reboot
    @logger.info "Restarting Rasberry Pi: #{@pi}"
    sudo_run 'sudo shutdown -r now'
    wait_for_sshd(@pi) { print '.'}
    @logger.info "Restarting Done."
  end

  private

    def sudo_run(cmd)
      run "sudo #{cmd}"
    end

    def run(cmd)
      @cap.run "#{cmd}"
    end

    def upload(source, target)
      @cap.upload source, target
    end

    def gem_install(gems)
      sudo_run "gem install --no-rdoc --no-ri #{gems}"
    end

    def apt_remove(packages)
      sudo_run "DEBIAN_FRONTEND=noninteractive apt-get purge -o DPkg::Options::=--force-confnew --force-yes -fuy  --auto-remove #{packages}"
    end

    def apt_install(packages)
      sudo_run "DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Options::=--force-confnew --force-yes -fuy install #{packages}"
    end

    def apt_upgrade
      sudo_run 'DEBIAN_FRONTEND=noninteractive apt-get update'
      sudo_run 'DEBIAN_FRONTEND=noninteractive apt-get -o DPkg::Options::=--force-confnew --force-yes -fuy upgrade'
    end

    def upload_key
      run 'mkdir ~/.ssh | true'
      upload "#{ENV["HOME"]}/.ssh/id_rsa.pub", '.ssh/authorized_keys'
      run 'chmod 600 ~/.ssh/authorized_keys'
      run 'chmod 700 ~/.ssh/'
    end

    def wait_for_sshd(hostname)
      until tcp_test_ssh(hostname, 22) { sleep 3 }
        yield if block_given?
      end
    end

    def tcp_test_ssh(hostname, ssh_port)
      tcp_socket = TCPSocket.new(hostname, ssh_port)
      readable = IO.select([tcp_socket], nil, nil, 5)
      if readable
        yield
        true
      else
        false
      end
    rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
      sleep 2
      false
    rescue Errno::EPERM, Errno::ETIMEDOUT
      false
    ensure
      tcp_socket && tcp_socket.close
    end
end
