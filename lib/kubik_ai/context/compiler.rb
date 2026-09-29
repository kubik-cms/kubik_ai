# frozen_string_literal: true

module KubikAi
  module Context
    class Compiler
      def self.compile(scopes: nil)
        new(scopes: scopes).compile
      end

      def initialize(scopes: nil)
        @scopes = KubikAi::Context::Scopes.normalize_list(scopes)
      end

      def compile
        sections = KubikAi.config.context_providers.filter_map do |key, provider_class|
          provider = provider_class.new
          next unless provider.available?

          content = provider.to_prompt.strip
          next if content.blank?

          "## #{provider.heading || key.to_s.humanize}\n#{content}"
        end

        sections.concat(feature_instruction_sections)
        sections.join("\n\n")
      end

      private

      def feature_instruction_sections
        return [] if @scopes.empty?

        config = Kubik::AiConfiguration.instance
        instructions = config.context_instructions.with_indifferent_access

        @scopes.filter_map do |scope|
          text = instructions[scope].to_s.strip
          next if text.blank?

          "## #{KubikAi::Context::Scopes.heading(scope)}\n#{text}"
        end
      rescue StandardError
        []
      end
    end
  end
end
