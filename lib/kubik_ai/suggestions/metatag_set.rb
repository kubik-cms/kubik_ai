# frozen_string_literal: true

module KubikAi
  module Suggestions
    class MetatagSet
      FIELDS = [
        { key: "title_tag", label: "Title tag", type: :text },
        { key: "meta_description", label: "Meta description", type: :textarea },
        { key: "og_title", label: "OG title", type: :text },
        { key: "og_description", label: "OG description", type: :textarea },
        { key: "twitter_title", label: "Twitter title", type: :text },
        { key: "twitter_description", label: "Twitter description", type: :textarea },
        { key: "twitter_card_type", label: "Twitter card type", type: :text }
      ].freeze

      def self.for(_record)
        Set.new(
          FIELDS.map do |field|
            Field.new(
              field[:key],
              label: field[:label],
              type: field[:type],
              empty_current_message: "Not set",
              hint: "Review before applying."
            )
          end
        )
      end
    end
  end
end
