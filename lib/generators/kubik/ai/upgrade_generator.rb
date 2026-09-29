# frozen_string_literal: true

require "rails/generators/active_record"

module Kubik
  module Generators
    module Ai
      class UpgradeGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("templates", __dir__)
        desc "Copy pending Kubik AI migrations into the host application (run after updating the gem)"
        argument :name, type: :string, default: "kubik_ai"

        def add_context_instructions_migration
          if context_instructions_column_present?
            say "kubik_ai_configurations.context_instructions already present — no migration added.", :green
            return
          end

          migration_template(
            "add_context_instructions_to_kubik_ai_configurations.rb.erb",
            "db/migrate/add_context_instructions_to_kubik_ai_configurations.rb",
            migration_version: migration_version
          )
        end

        def upgrade_notice
          say "Run bin/rails db:migrate when migrations were added.", :green
        end

        private

        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end

        def context_instructions_column_present?
          return false unless ActiveRecord::Base.connection.table_exists?(:kubik_ai_configurations)

          ActiveRecord::Base.connection.column_exists?(:kubik_ai_configurations, :context_instructions)
        rescue StandardError
          false
        end
      end
    end
  end
end
