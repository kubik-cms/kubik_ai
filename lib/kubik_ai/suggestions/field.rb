# frozen_string_literal: true

module KubikAi
  module Suggestions
    class Field
      attr_reader :key, :label, :type, :empty_current_message, :hint

      def initialize(key, label:, type:, empty_current_message: "Not set", hint: nil)
        @key = key.to_s
        @label = label
        @type = type.to_sym
        @empty_current_message = empty_current_message
        @hint = hint
      end

      def current_value(previous)
        value = previous[@key]
        value = value.presence
        return empty_current_message if value.blank?

        case type
        when :tags
          KubikAi::Media::TagList.normalize(value).join(", ")
        else
          value.to_s
        end
      end

      def suggested_value(pending)
        pending[@key]
      end
    end
  end
end
