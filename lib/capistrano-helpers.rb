require 'capistrano'

unless Capistrano::Configuration.respond_to?(:instance)
  abort "capistrano-helpers requires Capistrano 2"
end

class CapistranoHelpers

  # Execute the given block of code within the context of the capistrano
  # configuration.
  def self.with_configuration(&block)
    Capistrano::Configuration.instance(:must_exist).load(&block)
  end
end

CapistranoHelpers.with_configuration do

  def fetch_param(param, default=nil)
    send(param) if exists?(param)
    default || begin
      puts "Missing parameter: #{param}"
      exit 1
    end
  end
end
