$:.unshift 'lib'

require 'raspberry'
require 'capistrano-helpers'

set :application, 'raspberrypi-chef-solo'
set :repository,  'git://github.com/andrzejsliwa/raspberrypi-chef-solo.git'
set :branch,      'master'

server '192.168.1.50', :raspberry

set :user,      'pi'

set :rasp_pi, Raspberry.new(
  capistrano:   self,
  chef_version: '11.2.0',
  chef_dir:     'chef',
  chef_role:    'pi',
  pi:           find_servers(roles: :raspberry)[0]

)

namespace :pi do

  before 'provision', 'update_modules'

  desc 'updates modules from librarian'
  desc :update_modules do
    system 'cd chef; librarian-chef install; cd ..'
  end

  desc 'bootsrap raspberry pi'
  task :bootstrap do
    rasp_pi.bootstrap
    rasp_pi.reboot
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
