# frozen_string_literal: true

module KubikAi
  module Context
    module Providers
      class MetatagableContent < Base
        DEFAULT_LIMIT = 8_000

        def initialize(metatagable: nil, limit: DEFAULT_LIMIT)
          @metatagable = metatagable
          @limit = limit
        end

        def available?
          @metatagable.present?
        end

        def heading
          "Page content"
        end

        def to_prompt
          extract_text(@metatagable).truncate(@limit)
        end

        private

        def extract_text(record)
          parts = []
          parts << record.title if record.respond_to?(:title) && record.title.present?
          parts << record.name if record.respond_to?(:name) && record.name.present?
          parts << record.header if record.respond_to?(:header) && record.header.present?
          parts << record.subheader if record.respond_to?(:subheader) && record.subheader.present?
          parts << record.listing_summary if record.respond_to?(:listing_summary) && record.listing_summary.present?
          parts << record.description if record.respond_to?(:description) && record.description.present?
          parts << plain_content(record.content) if record.respond_to?(:content) && record.content.present?
          parts << plain_content(record.additional_content) if record.respond_to?(:additional_content) && record.additional_content.present?
          parts.compact.join("\n\n")
        end

        def plain_content(raw)
          return "" if raw.blank?

          if defined?(Kubik::WysiwygHelper)
            strip_tags = ActionController::Base.helpers
            strip_tags.sanitize(raw.to_s, tags: [])
          else
            raw.to_s
          end
        end
      end
    end
  end
end
