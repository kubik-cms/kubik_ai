# frozen_string_literal: true

namespace :kubik do
  namespace :ai do
    desc "Install Kubik AI migrations and initializers (see also: bin/rails generate kubik:ai:install)"
    task install: :environment do
      require "rails/generators"
      Rails::Generators.invoke("kubik:ai:install")
    end

    desc "Add pending Kubik AI migrations (see also: bin/rails generate kubik:ai:upgrade)"
    task upgrade: :environment do
      require "rails/generators"
      Rails::Generators.invoke("kubik:ai:upgrade")
    end
  end
end
