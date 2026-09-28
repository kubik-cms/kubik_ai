# frozen_string_literal: true

module KubikAi
  module Context
    module Providers
      class Site < Base
        def heading
          "Site AI context"
        end

        def available?
          configuration.present?
        end

        def to_prompt
          config = configuration
          return "" unless config

          lines = []
          lines << config.site_context if config.site_context.present?

          flags = config.feature_flags.with_indifferent_access
          lines << "Emphasize SEO keywords in alt text when relevant." if flags[:seo_keyword_emphasis]
          lines << "Prefer tags that avoid identifying individuals (e.g. 'no faces')." if flags[:prefer_no_faces]
          lines << "Tag vocabulary hints: #{flags[:tag_vocabulary_hints]}" if flags[:tag_vocabulary_hints].present?

          lines.compact.join("\n")
        end
      end
    end
  end
end
