$:.unshift 'lib'

require 'raspberry'
require 'capistrano-helpers'

set :application, 'raspberrypi-chef-solo'
set :repository,  'git://github.com/andrzejsliwa/raspberrypi-chef-solo.git'
set :branch,      'master'

server '192.168.1.50', :raspberry

set :chef_role, 'pi'
set :user,      'pi'

set :rasp_pi, Raspberry.new(
	capistrano: self, 
	logger: logger, 
	chef_version: '11.2.0',
	pi: find_servers(roles: :raspberry)[0], 
	chef_role: chef_role
)


namespace :pi do

  desc "bootsrap raspberry pi"
  task :bootstrap do
    rasp_pi.bootstrap
    rasp_pi.reboot
  end

  desc "provision raspberry pi"
  task :provision do
  	rasp_pi.provision
  end
end