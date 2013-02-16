root = File.expand_path("/tmp/ami_builder/chef")

file_cache_path "#{root}/cache"
cookbook_path   "#{root}/cookbooks"
role_path       "#{root}/roles"
data_bag_path   "#{root}/data_bags"
log_level :info
