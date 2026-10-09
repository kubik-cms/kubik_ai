# frozen_string_literal: true

module KubikAi
  module Media
    module TagList
      DEFAULT_MAX_TAGS = 5
      MAX_ALLOWED_TAGS = 20

      NOISE_TAGS = %w[
        no yes none null n/a na unknown other misc miscellaneous
        face faces people humans human person persons nothing
      ].freeze

      module_function

      def normalize(raw, from_llm: false, max_tags: nil)
        tags = extract_tags(raw, from_llm: from_llm)
        tags = tags.map { |tag| tag.to_s.strip.downcase }.reject(&:blank?)
        tags = tags.reject { |tag| noise_tag?(tag) }
        tags = tags.uniq
        limit = max_tags.nil? ? (from_llm ? ai_max_tags : nil) : max_tags.to_i
        limit = nil unless limit&.positive?
        limit = [limit, MAX_ALLOWED_TAGS].min if limit
        tags = tags.first(limit) if limit
        tags
      end

      def normalize_ai_tags(raw)
        normalize(raw, from_llm: true, max_tags: ai_max_tags)
      end

      def assign_to_upload!(upload, raw)
        return unless upload.respond_to?(:set_tag_list_on)

        tags = normalize_ai_tags(raw)
        return if tags.empty?

        upload.set_tag_list_on(:media_tags, tags)
      end

      def ai_max_tags
        return DEFAULT_MAX_TAGS unless defined?(KubikAi::ResourceSettings)

        KubikAi::ResourceSettings.media_value(:media_max_tags)
      rescue StandardError
        DEFAULT_MAX_TAGS
      end

      def extract_tags(raw, from_llm:)
        raw = parse_json_if_needed(raw)

        case raw
        when Array
          raw.flat_map { |entry| split_entry(entry, from_llm: from_llm) }
        when String
          split_entry(raw, from_llm: from_llm)
        else
          if raw.respond_to?(:to_a)
            Array(raw).flat_map { |entry| split_entry(entry, from_llm: from_llm) }
          else
            []
          end
        end
      end

      def split_entry(entry, from_llm: false)
        str = entry.to_s.strip
        return [] if str.blank?

        if str.include?(",") || str.include?(";")
          return str.split(/[,;]+/).map(&:strip).reject(&:blank?)
        end

        if !from_llm && str.match?(/\s/)
          return str.split(/\s+/).map(&:strip).reject(&:blank?)
        end

        [str]
      end

      def noise_tag?(tag)
        NOISE_TAGS.include?(tag) || tag.length < 2
      end

      def parse_json_if_needed(raw)
        return raw unless raw.is_a?(String)

        stripped = raw.strip
        return raw unless stripped.start_with?("[", "{")

        JSON.parse(stripped)
      rescue JSON::ParserError
        raw
      end
    end
  end
end
