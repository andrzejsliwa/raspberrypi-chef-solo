class Raspberry
  def initialize(options)
    @cap          = options.fetch(:capistrano)
    @pi           = options.fetch(:pi).to_s
    @chef_version = options.fetch(:chef_version)
    @chef_dir     = options.fetch(:chef_dir)
    @chef_role    = options.fetch(:chef_role)
    @noip_account = options.fetch(:noip_account)
    @archive_name = 'chef.tar.gz'
    @tmp_chef_dir = "/tmp/#{@chef_dir}"
  end

  def bootstrap
    logger.info 'bootstraping... '
    apt_upgrade

    pkgs_to_remove = [
      'scratch',
      'debian-reference-en dillo idle3 python3-tk idle python-pygame python-tk',
      'lightdm gnome-themes-standard gnome-icon-theme raspberrypi-artwork',
      'gvfs-backends gvfs-fuse desktop-base lxpolkit netsurf-gtk zenity xdg-utils',
      'mupdf gtk2-engines alsa-utils  lxde lxtask menu-xdg gksu',
      'midori xserver-xorg xinit xserver-xorg-video-fbdev',
      'libraspberrypi-dev libraspberrypi-doc',
      'dbus-x11 libx11-6 libx11-data libx11-xcb1 x11-common x11-utils',
      'lxde-icon-theme gconf-service gconf2-common'
    ].join(' ')
    apt_remove(pkgs_to_remove)

    pkgs_to_install = [
      'build-essential git-core',
      'ruby1.9.3 ruby1.9.1-dev libopenssl-ruby libxml2-dev libxslt-dev',
      'htop mc tmux',
    ].join(' ')
    apt_install(pkgs_to_install)

    gem_install "chef --version=#{@chef_version}"
    gem_install "tmuxinator"

    sudo_run %{sh -c "echo 'PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/var/lib/gems/1.8/bin\"' > /etc/environment"%}

    upload_key
    sudo_run 'curl -L https://raw.github.com/andrzejsliwa/vimfiles/master/utils/installer.sh | sh'
    run 'curl -L https://raw.github.com/andrzejsliwa/vimfiles/master/utils/installer.sh | sh'

    install_noip

    logger.info 'bootstrap done.'
  end

  def provision
    logger.info 'provisioning...'

    system "rm -f #{@archive_name} && tar czf #{@archive_name} #{@chef_dir}"
    sudo_run "rm -rf #{@tmp_chef_dir}"

    upload @archive_name, '/tmp'

    run "cd /tmp && tar xzf #{@archive_name}"
    sudo_run %{chef-solo -c #{@tmp_chef_dir}/solo.rb -o "role[#{@chef_role}]"}

    logger.info 'provision done.'
  end

  def reboot
    logger.info "rebooting #{@pi} ..."

    sudo_run 'sudo shutdown -r now'
    wait_for_sshd(@pi) { print '.' }

    logger.info 'reboot done.'
  end

  def install_noip
    logger.info 'installing noip'

    sudo_run '/etc/init.d/noip stop || true'
    run 'wget http://www.no-ip.com/client/linux/noip-duc-linux.tar.gz'
    run 'tar vzxf noip-duc-linux.tar.gz'
    run 'cd noip-*; sudo make'

    noip_password = Capistrano::CLI.password_prompt("Type your noip password: ")

    @cap.run 'cd noip-*; sudo make install' do |ch, stream, out|
      ch.send_data "#{@noip_account}\n"  if out =~ /Please enter the login.*/
      ch.send_data "#{noip_password}\r" if out =~ /Please enter the password.*/
      ch.send_data "10\n\n"   if out =~ /Please enter an update interval.*/
      ch.send_data "n\n"    if out =~ /Do you wish to run something at successful update\?\[N\] \(y\/N\)/
    end
    upload 'templates/noip', '/tmp/noip'
    sudo_run 'mv /tmp/noip /etc/init.d/noip'
    sudo_run 'chmod 755 /etc/init.d/noip'
    sudo_run '/etc/init.d/noip start'
    sudo_run 'sudo update-rc.d noip defaults'

    logger.info 'installing noip done.'
  end

  private

    def logger
      @cap.logger
    end

    def sudo_run(cmd)
      run "sudo #{cmd}"
    end

    def run(cmd)
      @cap.run "#{cmd}"
    end

    def upload(source, target)
      @cap.upload source, target, force: true, via: :scp
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
