module RLM
  class Setup

    cattr_reader :yaml_config

    class << self

      def yaml_config
        if @@yaml_config.nil?
          config_path = File.expand_path("../../../config/rlm_settings.yml", __FILE__)
          @@yaml_config = YAML::load(File.open(config_path).read)
        end

        @@yaml_config
      end

      def name_for(name, current_module_scope: nil)
        [naming_prefix, current_module_scope.try(:parameterize), name.parameterize].compact.join("-")
      end

      def module_name
        yaml_config['module_name']
      end

      def naming_prefix
        yaml_config['naming_prefix']
      end

    end


    module RlmAttributeSetterExtensions

      extend ActiveSupport::Concern

      included do |base|

        cattr_reader :required_entries_from_config
        cattr_reader :to_create_classname_from_config
        cattr_reader :identify_column_from_config

        # Get Ident key from 'rlm_settings.yml' based on the class the module is included in
        def self.rlm_module_name_for_config
          self.name.split('::').last.underscore
        end

        def self.required_entries_from_config
          @@required_entries_from_config ||= Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['entries']
        end

        def self.to_create_classname_from_config
          @@to_create_classname_from_config = Setup.yaml_config['modules']['setup'][rlm_module_name_for_config]['class_name'].constantize
        end

      end


    end

    class Activities

      include RlmAttributeSetterExtensions

      class << self

        # TODO: Abstract and move values to YML file

        def license
          t = ::TimeEntryActivity.find_or_initialize_by(internal_name: Setup.name_for('license'))

          if t.new_record?
            t.name = 'License'
            t.save
          end

          return t
        end

        def maintenance
          t = ::TimeEntryActivity.find_or_initialize_by(internal_name: Setup.name_for('maintenance'))

          if t.new_record?
            t.name = 'Maintenance'
            t.save
          end

          return t
        end

        def all
          [ license, maintenance ]
        end
      end
    end

    module Trackers
      class << self

        # TODO: Abstract and move values to YML file

        def license
          t = ::Tracker.find_or_initialize_by(internal_name: Setup.name_for('license'), default_status_id: IssueStatuses.inactive.id)

          if t.new_record?
            t.name = 'License'
            t.save
          end

          return t
        end

        def license_extension
          t = ::Tracker.find_or_initialize_by(internal_name: Setup.name_for('license_extension'), default_status_id: IssueStatuses.inactive.id)

          if t.new_record?
            t.name = 'LicenseExtension'
            t.save
          end

          return t
        end

        def all
          [license, license_extension]
        end
      end
    end

    module IssueStatuses
      class << self

        # TODO: IssueStatus has no internal name, which makes this very fragile

        def active
          ::IssueStatus.find_or_create_by(name: 'License active')
        end

        def inactive
          ::IssueStatus.find_or_create_by(name: 'License inactive')
        end

      end
    end

    module Workflows

    end

    module Projects

      class << self

        def license_manager_projects
          ::Project.has_module(Setup::MODULE_NAME)
        end

        def default_license_manager_project
          if license_manager_projects.any?
            license_manager_projects.first
          else
            # Setup an inital Project
            project = ::Project.create(name: 'Redmine License Manager')

            convert_to_license_manager_project!(project)

            return license_manager_projects.first
          end
        end

        def convert_to_license_manager_project!(project)
          # Checking what needs to be done
          status = check_license_manager_project_integrity(project)

          ::EnabledModule.create(project_id: project.id, name: Setup::MODULE_NAME) if status[:module] == false

          # Reset/Assign Trackers
          project.trackers = Trackers.all if status[:trackers] == false

          # Reset/Assign Activities
          project.time_entry_activities = Activities.all if status[:activities] == false

          project.save

          return project
        end

        def check_license_manager_project_integrity(project)
          status = {}
          status[:module]       = project.module_enabled?(Setup::MODULE_NAME)
          status[:trackers]     = (project.trackers == Trackers.all)
          status[:activities]   = (project.time_entry_activities == Activities.all)

          status[:valid]        = !status.values.include?(false)

          return status
        end

      end

    end

  end
end