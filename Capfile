$:.unshift 'lib'

require 'raspberry'
require 'capistrano-helpers'

set :application, 'raspberrypi-chef-solo'
set :repository,  'git@github.com:andrzejsliwa/raspberrypi-chef-solo.git'
set :branch,      'master'

server '192.168.1.50', :raspberry

set :rasp_pi,     Raspberry.new(capistrano: self, logger: logger, chef_version: '11.2.0', pi: find_servers(roles: :raspberry)[0])
set :user,        'pi'


namespace :pi do

  desc "bootsrap raspberry pi"
  task :bootstrap do
    rasp_pi.bootstrap
    rasp_pi.reboot
  end
end