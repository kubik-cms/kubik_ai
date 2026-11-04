# frozen_string_literal: true

module KubikAi
  class GenerateLlmsTxtJob < ApplicationJob
    queue_as :default

    def perform(setting_id = nil, instructions: nil)
      setting = if setting_id && defined?(Kubik::Setting)
                  Kubik::Setting.find_by(id: setting_id) || Kubik::Setting.instance
                else
                  Kubik::Setting.instance
                end

      KubikAi::LlmsTxt::Suggestor.call(setting: setting, instructions: instructions)
    end
  end
end
