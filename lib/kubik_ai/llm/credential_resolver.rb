# frozen_string_literal: true

module KubikAi
  module Llm
    class CredentialResolver
      PROVIDER_ENV_KEYS = {
        openai: "OPENAI_API_KEY",
        anthropic: "ANTHROPIC_API_KEY",
        gemini: "GEMINI_API_KEY",
        google: "GEMINI_API_KEY"
      }.freeze

      def self.apply!(config: Kubik::AiConfiguration.instance)
        new(config).apply!
      end

      def initialize(config)
        @config = config
      end

      def apply!
        if @config.credential_source == "database"
          apply_database_credentials!
        else
          apply_env_credentials!
        end
      end

      private

      def apply_database_credentials!
        creds = @config.provider_credentials.with_indifferent_access
        RubyLLM.configure do |c|
          c.openai_api_key = creds[:openai_api_key] if creds[:openai_api_key].present?
          c.anthropic_api_key = creds[:anthropic_api_key] if creds[:anthropic_api_key].present?
          c.gemini_api_key = creds[:gemini_api_key] if creds[:gemini_api_key].present?
        end
      end

      def apply_env_credentials!
        RubyLLM.configure do |c|
          PROVIDER_ENV_KEYS.each do |_provider, env_key|
            value = ENV[env_key]
            next if value.blank?

            case env_key
            when "OPENAI_API_KEY"
              c.openai_api_key = value
            when "ANTHROPIC_API_KEY"
              c.anthropic_api_key = value
            when "GEMINI_API_KEY"
              c.gemini_api_key = value
            end
          end
        end
      end
    end
  end
end
