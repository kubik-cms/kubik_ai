# frozen_string_literal: true

module KubikAi
  module Metatag
    module Focus
      SCOPES = {
        "seo" => %w[title_tag meta_description],
        "seo_title" => %w[title_tag],
        "meta_description" => %w[meta_description],
        "social" => %w[
          og_title og_description og_type
          twitter_title twitter_description twitter_card_type
        ]
      }.freeze

      PANEL_HEADERS = {
        "seo" => "AI search & sharing",
        "seo_title" => "AI title tag",
        "meta_description" => "AI meta description",
        "social" => "AI social sharing"
      }.freeze

      TRIGGER_LABELS = {
        "seo" => "Suggest SEO with AI",
        "seo_title" => "Suggest title with AI",
        "meta_description" => "Suggest description with AI",
        "social" => "Suggest social tags with AI"
      }.freeze

      module_function

      def all
        SCOPES.keys
      end

      def fields_for(focus)
        return SCOPES.values.flatten.uniq if focus.blank? || focus == "full"

        key = focus.to_s
        return SCOPES.fetch(key) if SCOPES.key?(key)

        SCOPES.values.flatten.uniq
      end

      def normalize(focus)
        focus.presence || "full"
      end

      def scoped?(focus)
        focus.present? && focus != "full"
      end

      def panel_header(focus)
        return "AI meta suggestions" if focus.blank? || focus == "full"

        PANEL_HEADERS.fetch(focus.to_s, "AI meta suggestions")
      end

      def trigger_label(focus)
        return "AI meta assistant" if focus.blank? || focus == "full"

        TRIGGER_LABELS.fetch(focus.to_s, "AI meta assistant")
      end

      def storage_suffix(focus)
        scoped?(focus) ? focus.to_s : nil
      end
    end
  end
end
