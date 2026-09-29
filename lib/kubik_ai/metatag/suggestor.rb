# frozen_string_literal: true

module KubikAi
  module Metatag
    class Suggestor
      JSON_FIELDS = %w[
        title_tag meta_description og_title og_description og_type
        twitter_title twitter_description twitter_card_type notes
      ].freeze

      def self.call(metatagable:, broadcast: true, focus: nil, instructions: nil)
        new(metatagable: metatagable, broadcast: broadcast, focus: focus, instructions: instructions).call
      end

      def initialize(metatagable:, broadcast: true, focus: nil, instructions: nil)
        @metatagable = metatagable
        @broadcast = broadcast
        @focus = Focus.normalize(focus)
        @instructions = instructions.to_s.strip.presence
      end

      def call
        ensure_enabled!

        context = compile_context
        prompt = build_prompt(context)
        result = KubikAi::Llm::Gateway.complete_json!(
          prompt: prompt,
          operation: "metatag_suggest",
          subject: @metatagable
        )

        SuggestionStore.store!(@metatagable, result, focus: scoped_focus)
        Broadcaster.broadcast!(@metatagable) if @broadcast
        result
      end

      private

      def scoped_focus
        Focus.scoped?(@focus) ? @focus : nil
      end

      def ensure_enabled!
        config = Kubik::AiConfiguration.instance
        raise KubikAi::FeatureDisabled, "AI is disabled" unless config.enabled
        unless config.meta_tag_suggestions
          raise KubikAi::FeatureDisabled, "Meta tag suggestions are disabled"
        end
      end

      def compile_context
        scopes = KubikAi::Context::Scopes.for_metatag_focus(@focus)
        site_context = KubikAi::Context::Compiler.compile(scopes: scopes)
        content_provider = KubikAi::Context::Providers::MetatagableContent.new(metatagable: @metatagable)
        content_section = if content_provider.available?
                            "## #{content_provider.heading}\n#{content_provider.to_prompt}"
                          else
                            ""
                          end

        [site_context, content_section].reject(&:blank?).join("\n\n")
      end

      def build_prompt(context)
        emphasis = Kubik::AiConfiguration.instance.seo_keyword_emphasis ? "Emphasize relevant SEO keywords naturally." : ""

        prompt = <<~PROMPT
          You suggest SEO and social meta tags for a CMS page. #{emphasis}

          #{context}

          Respond with JSON only, no markdown fences:
          #{focused_json_schema}
        PROMPT

        return prompt if @instructions.blank?

        <<~PROMPT.strip
          #{prompt}

          Administrator instructions for this suggestion run (follow when compatible with CMS rules):
          #{@instructions}
        PROMPT
      end

      def focused_json_schema
        case @focus
        when "seo_title"
          <<~JSON.strip
            {
              "title_tag": "browser title, max ~60 chars",
              "notes": "optional brief rationale for administrators"
            }
          JSON
        when "meta_description"
          <<~JSON.strip
            {
              "meta_description": "meta description, max ~160 chars",
              "notes": "optional brief rationale for administrators"
            }
          JSON
        when "seo"
          <<~JSON.strip
            {
              "title_tag": "browser title, max ~60 chars",
              "meta_description": "meta description, max ~160 chars",
              "notes": "optional brief rationale for administrators"
            }
          JSON
        when "social"
          <<~JSON.strip
            {
              "og_title": "Open Graph title",
              "og_description": "Open Graph description",
              "og_type": "website or article",
              "twitter_title": "Twitter card title",
              "twitter_description": "Twitter card description",
              "twitter_card_type": "summary or summary_large_image",
              "notes": "optional brief rationale for administrators"
            }
          JSON
        else
          <<~JSON.strip
            {
              "title_tag": "browser title, max ~60 chars",
              "meta_description": "meta description, max ~160 chars",
              "og_title": "Open Graph title",
              "og_description": "Open Graph description",
              "og_type": "website or article",
              "twitter_title": "Twitter card title",
              "twitter_description": "Twitter card description",
              "twitter_card_type": "summary or summary_large_image",
              "notes": "optional brief rationale for administrators"
            }
          JSON
        end
      end
    end
  end
end
