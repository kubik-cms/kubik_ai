# frozen_string_literal: true

module KubikAi
  module Context
    module Scopes
      INSTRUCTION_KEYS = %i[media seo social].freeze

      HEADINGS = {
        media: "Media library (alt text & tags)",
        seo: "SEO & search targeting",
        social: "Social sharing"
      }.freeze

      module_function

      def heading(scope)
        HEADINGS[scope.to_sym] || scope.to_s.humanize
      end

      def normalize_list(scopes)
        return [] if scopes.nil?

        Array(scopes).filter_map do |scope|
          key = scope.to_sym
          INSTRUCTION_KEYS.include?(key) ? key : nil
        end.uniq
      end

      def for_metatag_focus(focus)
        case focus.to_s
        when "social"
          [:social]
        when "seo", "seo_title", "meta_description"
          [:seo]
        when "full", ""
          [:seo, :social]
        else
          [:seo, :social]
        end
      end
    end
  end
end
