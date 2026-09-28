# frozen_string_literal: true

module KubikAi
  module Media
    module TagList
      module_function

      def normalize(raw)
        raw = parse_json_if_needed(raw)

        parts = case raw
                when Array
                  raw.flat_map { |entry| split_entry(entry) }
                when String
                  split_entry(raw)
                else
                  if raw.respond_to?(:to_a)
                    Array(raw).flat_map { |entry| split_entry(entry) }
                  else
                    []
                  end
                end

        parts.map { |tag| tag.to_s.strip.downcase }.reject(&:blank?).uniq
      end

      def assign_to_upload!(upload, raw)
        return unless upload.respond_to?(:set_tag_list_on)

        tags = normalize(raw)
        return if tags.empty?

        upload.set_tag_list_on(:media_tags, tags)
      end

      def split_entry(entry)
        str = entry.to_s.strip
        return [] if str.blank?

        if str.include?(",") || str.include?(";")
          return str.split(/[,;]+/).map(&:strip).reject(&:blank?)
        end

        if str.match?(/\s/)
          return str.split(/\s+/).map(&:strip).reject(&:blank?)
        end

        [str]
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
