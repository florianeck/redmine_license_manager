# All Settings for the Project are handled in the setup.rb file and the corresponding yaml file
require File.expand_path("../lib/rlm/setup.rb", __FILE__)

Redmine::Plugin.register RLM::Setup.module_name do
  name 'Redmine License Manager'
  author 'Florian Eck for akquinet'
  description 'License Manager'
  version '0.1.0'

  Redmine::AccessControl.map do |map|
    map.project_module RLM::Setup.module_name do |pmap|
      RLM::Setup.permissions_config.each do |permission_name, settings|
        pmap.permission "#{RLM::Setup.naming_prefix}_#{permission_name}", settings
      end
    end
  end
end

