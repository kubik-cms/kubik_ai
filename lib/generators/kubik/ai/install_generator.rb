# frozen_string_literal: true

require "rails/generators/active_record"

module Kubik
  module Generators
    module Ai
      class InstallGenerator < ActiveRecord::Generators::Base
        source_root File.expand_path("templates", __dir__)
        desc "Install Kubik AI tables and initializers"
        argument :name, type: :string, default: "application"

        def db_migrations
          migration_template "create_kubik_ai_configurations.rb.erb",
                             "db/migrate/create_kubik_ai_configurations.rb",
                             migration_version: migration_version
          migration_template "create_kubik_ai_usage_events.rb.erb",
                             "db/migrate/create_kubik_ai_usage_events.rb",
                             migration_version: migration_version
        end

        def copy_initializer
          template "kubik_ai.rb.erb", "config/initializers/kubik_ai.rb"
        end

        def copy_ruby_llm_initializer
          template "ruby_llm.rb.erb", "config/initializers/ruby_llm.rb"
        end

        def copy_filter_logging_snippet
          say "Add :provider_credentials to config/initializers/filter_parameter_logging.rb if not already filtered.",
              :yellow
        end

        def encryption_notice
          say "Active Record encryption is required for database-stored API keys.", :green
          say "Run: bin/rails db:encryption:init and add keys to credentials or ENV.", :green
        end

        private

        def migration_version
          "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
        end
      end
    end
  end
end
