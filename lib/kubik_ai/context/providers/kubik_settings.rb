# frozen_string_literal: true

module KubikAi
  module Context
    module Providers
      class KubikSettings < Base
        def available?
          defined?(Kubik::Setting)
        end

        def heading
          "Organisation"
        end

        def to_prompt
          setting = Kubik::Setting.instance
          hash = setting.settings_hash.with_indifferent_access
          lines = []
          %i[site_name company_name site_title].each do |key|
            value = hash[key].presence || (setting.respond_to?(key) ? setting.send(key) : nil)
            lines << "#{key.to_s.humanize}: #{value}" if value.present?
          end
          lines.join("\n")
        rescue StandardError
          ""
        end
      end
    end
  end
end
