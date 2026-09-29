# frozen_string_literal: true

module KubikAi
  module Metatag
    # Declare which record attributes are sent to the LLM when suggesting meta tags.
    module ContentFields
      extend ActiveSupport::Concern

      FORMAT_TEXT = :text
      FORMAT_WYSIWYG = :wysiwyg

      class_methods do
        def kubik_ai_metatag_content_settings
          @kubik_ai_metatag_content_settings
        end

        # @example kubik_ai_metatag_content :header, :subheader, content: :wysiwyg
        def kubik_ai_metatag_content(*plain_fields, **typed_fields)
          specs = plain_fields.map { |field| { field: field, format: FORMAT_TEXT } }
          typed_fields.each do |field, format|
            specs << { field: field, format: (format.presence || FORMAT_WYSIWYG).to_sym }
          end
          @kubik_ai_metatag_content_settings = specs.freeze
        end
      end
    end

    class ContentExtractor
      LEGACY_FIELDS = [
        { field: :title, format: ContentFields::FORMAT_TEXT },
        { field: :name, format: ContentFields::FORMAT_TEXT },
        { field: :header, format: ContentFields::FORMAT_TEXT },
        { field: :subheader, format: ContentFields::FORMAT_TEXT },
        { field: :listing_summary, format: ContentFields::FORMAT_TEXT },
        { field: :description, format: ContentFields::FORMAT_TEXT },
        { field: :content, format: ContentFields::FORMAT_WYSIWYG },
        { field: :additional_content, format: ContentFields::FORMAT_WYSIWYG }
      ].freeze

      def self.extract(record)
        new(record).extract
      end

      def initialize(record)
        @record = record
      end

      def extract
        field_specs.flat_map { |spec| extract_field(spec) }.compact.join("\n\n")
      end

      private

      def field_specs
        settings = @record.class.kubik_ai_metatag_content_settings if @record.class.respond_to?(:kubik_ai_metatag_content_settings)
        settings.presence || LEGACY_FIELDS
      end

      def extract_field(spec)
        field = spec[:field]
        return unless @record.respond_to?(field)

        raw = @record.public_send(field)
        return if raw.blank?

        formatted = format_value(raw, spec[:format])
        formatted.presence
      end

      def format_value(raw, format)
        case format
        when ContentFields::FORMAT_WYSIWYG
          wysiwyg_plain_text(raw)
        else
          plain_text(raw)
        end
      end

      def plain_text(raw)
        text = raw.to_s.strip
        return "" if text.blank?

        if text.include?("<")
          ActionController::Base.helpers.strip_tags(text).squish
        else
          text.squish
        end
      end

      def wysiwyg_plain_text(raw)
        converter = KubikAi.config.plain_text_from_wysiwyg
        if converter.respond_to?(:call)
          converter.call(raw).to_s.strip
        else
          plain_text(raw)
        end
      end
    end
  end
end
