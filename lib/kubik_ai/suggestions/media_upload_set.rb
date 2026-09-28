# frozen_string_literal: true

module KubikAi
  module Suggestions
    class MediaUploadSet
      def self.for(_upload)
        Set.new(
          [
            Field.new(
              "alt_text",
              label: "Alt text",
              type: :textarea,
              empty_current_message: "No alt text yet",
              hint: "Describe the image for screen readers and SEO."
            ),
            Field.new(
              "tags",
              label: "Tags",
              type: :tags,
              empty_current_message: "No tags",
              hint: "Remove or edit tags before applying."
            )
          ]
        )
      end
    end
  end
end
