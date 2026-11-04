# frozen_string_literal: true

module KubikAi
  module LlmsTxt
    class Suggestor
      def self.call(setting: nil, instructions: nil)
        new(setting: setting, instructions: instructions).call
      end

      def initialize(setting: nil, instructions: nil)
        @setting = setting || (defined?(Kubik::Setting) ? Kubik::Setting.instance : nil)
        @instructions = instructions.to_s.strip.presence
      end

      def call
        ensure_enabled!

        context = compile_context
        prompt = build_prompt(context)
        body = KubikAi::Llm::Gateway.complete(
          prompt: prompt,
          operation: "llms_txt_suggest",
          subject: @setting
        )

        draft = body.to_s.strip
        persist_draft!(draft)
        draft
      end

      private

      def ensure_enabled!
        config = Kubik::AiConfiguration.instance
        raise KubikAi::FeatureDisabled, "AI is disabled" unless config.enabled
        raise KubikAi::FeatureDisabled, "llms.txt suggestions are disabled" unless config.llms_txt_suggestions
      end

      def compile_context
        scopes = [:llms_txt]
        site_context = KubikAi::Context::Compiler.compile(scopes: scopes, resource: nil)
        settings_context = settings_snapshot
        policy_context = policy_snapshot

        [site_context, settings_context, policy_context].reject(&:blank?).join("\n\n")
      end

      def settings_snapshot
        return "" unless @setting

        hash = (@setting.settings_hash || {}).with_indifferent_access
        <<~TEXT.strip
          ## Site settings snapshot
          Site title: #{hash[:site_title] || hash[:site_name]}
          Contact email: #{hash[:admin_email] || hash[:email]}
          Public URL: #{hash[:schema_organization_url] || hash.dig(:schema_organization, :url)}
        TEXT
      end

      def policy_snapshot
        return "" unless defined?(Kubik::Discoverability::PolicyResolver)

        summary = Kubik::Discoverability::PolicyResolver.policy_summary
        return "" if summary.blank?

        "## Effective crawler policy (must not contradict)\n#{summary}"
      end

      def build_prompt(context)
        base = <<~PROMPT
          You write llms.txt markdown for a public website (see https://llmstxt.org/).
          Use UK English unless site context says otherwise.
          Do not invent URLs. Respect the crawler policy summary.

          #{context}

          Output markdown only (no JSON, no code fences). Include:
          - H1 site name
          - Blockquote one-line summary
          - Sections for what the site is, key areas, and AI/crawler usage aligned with policy
        PROMPT

        return base if @instructions.blank?

        "#{base}\n\nAdministrator instructions:\n#{@instructions}"
      end

      def persist_draft!(draft)
        return unless @setting

        @setting.settings_hash = (@setting.settings_hash || {}).merge("llms_txt_ai_draft" => draft)
        @setting.save!
      end
    end
  end
end
