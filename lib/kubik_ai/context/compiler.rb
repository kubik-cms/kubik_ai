# frozen_string_literal: true

module KubikAi
  module Context
    class Compiler
      def self.compile
        new.compile
      end

      def compile
        sections = KubikAi.config.context_providers.filter_map do |key, provider_class|
          provider = provider_class.new
          next unless provider.available?

          content = provider.to_prompt.strip
          next if content.blank?

          "## #{provider.heading || key.to_s.humanize}\n#{content}"
        end

        sections.join("\n\n")
      end
    end
  end
end
