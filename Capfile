$:.unshift 'lib'

require 'raspberry'
require 'capistrano-helpers'

set :application, 'raspberrypi-chef-solo'
set :repository,  'git://github.com/andrzejsliwa/raspberrypi-chef-solo.git'
set :branch,      'master'

server 'pi.andrzejsliwa.com', :raspberry

set :user,      'pi'

set :rasp_pi, Raspberry.new(
  capistrano:   self,
  chef_version: '11.2.0',
  chef_dir:     'chef',
  chef_role:    'pi',
  noip_account: 'andrzej.sliwa@i-tool.eu',
  pi:           find_servers(roles: :raspberry)[0]
)

namespace :pi do

  before 'pi:provision', 'pi:update_modules'

  desc 'updates modules from librarian'
  task :update_modules do
    system 'cd chef; librarian-chef install; cd -'
  end

  desc 'bootsrap raspberry pi'
  task :bootstrap do
    rasp_pi.bootstrap
    rasp_pi.reboot
  end

  desc 'install noip for raspberry pi'
  task :install_noip do
    rasp_pi.install_noip
  end

  desc 'cleanup broken bootsrap'
  task :cleanup_bootstrap do
    rasp_pi.cleanup_bootstrap
  end

  desc 'provision raspberry pi'
  task :provision do
    rasp_pi.provision
  end

  desc 'reboot raspberry pi'
  task :reboot do
    rasp_pi.reboot
  end

  desc 'connect to pi'
  task :ssh do
    exec "ssh #{user}@#{find_servers(roles: :raspberry)[0]}"
  end
end
