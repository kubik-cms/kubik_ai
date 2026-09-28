# frozen_string_literal: true

module KubikAi
  module Context
    module Providers
      class Seo < Base
        def available?
          defined?(Kubik::Setting) && kubik_setting&.respond_to?(:meta_tag)
        end

        def heading
          "SEO"
        end

        def to_prompt
          setting = kubik_setting
          meta = setting.meta_tag
          return "" unless meta

          lines = []
          lines << "Default title tag: #{meta.title_tag}" if meta.title_tag.present?
          lines << "Default meta description: #{meta.meta_description}" if meta.meta_description.present?
          lines << "Open Graph title: #{meta.og_title}" if meta.og_title.present?
          lines << "Open Graph description: #{meta.og_description}" if meta.og_description.present?
          lines.join("\n")
        rescue StandardError
          ""
        end

        private

        def kubik_setting
          Kubik::Setting.instance
        rescue StandardError
          nil
        end
      end
    end
  end
end
