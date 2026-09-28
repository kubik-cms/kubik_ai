# frozen_string_literal: true

module KubikAi
  module Media
    class FormFieldRenderer
      FormShim = Struct.new(:object_name, :object, keyword_init: true)

      def self.tags_field_html(upload)
        new(upload).tags_field_html
      end

      def self.alt_text_value(upload)
        upload.additional_info["alt_text"].presence || upload.additional_info[:alt_text]
      end

      def initialize(upload)
        @upload = upload
      end

      def tags_field_html
        return "" unless defined?(KubikMediaLibrary) && KubikMediaLibrary.tagging_available?

        ApplicationController.render(
          partial: "admin/kubik_media_uploads/media_tags_field",
          locals: { image: FormShim.new(object_name: "media_upload", object: @upload) },
          helpers: ApplicationController.helpers
        )
      rescue StandardError => e
        ::Rails.logger.warn("[KubikAi] tags field render failed: #{e.message}")
        ""
      end
    end
  end
end
