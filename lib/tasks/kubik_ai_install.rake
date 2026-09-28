# frozen_string_literal: true

namespace :kubik do
  namespace :ai do
    desc "Install Kubik AI tables and initializers"
    task install: :environment do
      Rails::Generators.invoke("kubik:ai:install", %w[application])
    end
  end
end
