Redmine::Plugin.register :redmine_license_manager do
  name 'Redmine License Manager'
  author 'Florian Eck for akquinet'
  description 'License Manager'
  version '0.1.0'

  require File.expand_path("../lib/redmine_license_manager.rb", __FILE__)

  settings  :partial => 'rlm/settings',
            :default => { 'rlm_default_user_id' => 1, }

end

