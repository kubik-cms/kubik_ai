# frozen_string_literal: true

require "json"

module KubikAi
  module Llm
    class Gateway
      DEFAULT_ESTIMATE_CENTS = 1

      def self.analyze_image!(image_path:, operation:, subject: nil, instructions:)
        new.analyze_image!(image_path: image_path, operation: operation, subject: subject, instructions: instructions)
      end

      def self.ping!
        new.ping!
      end

      def self.complete_json!(prompt:, operation:, subject: nil, model: nil)
        new.complete_json!(prompt: prompt, operation: operation, subject: subject, model: model)
      end

      def ping!
        KubikAi::Usage::Limiter.check!
        config = Kubik::AiConfiguration.instance
        KubikAi::Llm::CredentialResolver.apply!(config: config)

        model = config.vision_model.presence || KubikAi.config.default_vision_model
        response = RubyLLM.chat(model: model).ask("Reply with exactly: ok")

        record_usage!(
          operation: "test_connection",
          model: model,
          response: response,
          status: "success"
        )
        response.content.to_s
      rescue KubikAi::SpendCapExceeded
        raise
      rescue StandardError => e
        record_usage!(
          operation: "test_connection",
          model: config&.vision_model,
          response: nil,
          status: "error",
          error_message: e.message
        )
        raise KubikAi::LlmError, e.message
      end

      def complete_json!(prompt:, operation:, subject: nil, model: nil)
        KubikAi::Usage::Limiter.check!
        config = Kubik::AiConfiguration.instance
        KubikAi::Llm::CredentialResolver.apply!(config: config)

        chat_model = model.presence || config.vision_model.presence || KubikAi.config.default_text_model
        response = RubyLLM.chat(model: chat_model).ask(prompt)
        parsed = parse_generic_json(response.content.to_s)

        record_usage!(
          operation: operation,
          model: chat_model,
          response: response,
          status: "success",
          subject: subject,
          metadata: { prompt_version: KubikAi.config.prompt_version }
        )

        parsed
      rescue KubikAi::SpendCapExceeded
        raise
      rescue StandardError => e
        record_usage!(
          operation: operation,
          model: model || config&.vision_model,
          response: nil,
          status: "error",
          error_message: e.message,
          subject: subject
        )
        raise KubikAi::LlmError, e.message
      end

      def analyze_image!(image_path:, operation:, subject: nil, instructions:)
        KubikAi::Usage::Limiter.check!
        config = Kubik::AiConfiguration.instance
        KubikAi::Llm::CredentialResolver.apply!(config: config)

        model = config.vision_model.presence || KubikAi.config.default_vision_model
        prompt = build_prompt(instructions, operation: operation)

        response = RubyLLM.chat(model: model).ask(prompt, with: image_path)
        parsed = parse_json_response(response.content.to_s)

        record_usage!(
          operation: operation,
          model: model,
          response: response,
          status: "success",
          subject: subject,
          metadata: { prompt_version: KubikAi.config.prompt_version }
        )

        parsed
      rescue KubikAi::SpendCapExceeded
        raise
      rescue StandardError => e
        record_usage!(
          operation: operation,
          model: config&.vision_model,
          response: nil,
          status: "error",
          error_message: e.message,
          subject: subject
        )
        raise KubikAi::LlmError, e.message
      end

      private

      def build_prompt(instructions, operation:)
        reinterpret = operation.to_s == "media_reinterpret"
        task = if reinterpret
                 "Re-suggest alt text and tags for this image. When editor additional instructions are present, treat them as mandatory."
               else
                 "Suggest alt text and tags for this image."
               end

        <<~PROMPT
          You analyze images for a content management system. #{task} Use the site context below.

          #{instructions}

          Respond with JSON only, no markdown fences:
          {
            "alt_text": "concise accessible alt text, plain text, max 125 characters",
            "tags": ["separate", "tags", "one", "per", "array", "item"],
            "notes": "optional brief rationale for administrators"
          }
        PROMPT
      end

      def parse_generic_json(content)
        stripped = content.to_s.strip
        stripped = stripped.gsub(/\A```json\s*/i, "").gsub(/\A```\s*/i, "").gsub(/\s*```\z/, "")
        JSON.parse(stripped)
      rescue JSON::ParserError => e
        raise KubikAi::LlmError, "Invalid JSON from model: #{e.message}"
      end

      def parse_json_response(content)
        data = parse_generic_json(content)
        {
          alt_text: data["alt_text"].to_s.strip,
          tags: KubikAi::Media::TagList.normalize(data["tags"]),
          notes: data["notes"].to_s.strip
        }
      rescue JSON::ParserError => e
        raise KubikAi::LlmError, "Invalid JSON from model: #{e.message}"
      end

      def record_usage!(operation:, model:, response:, status:, error_message: nil, subject: nil, metadata: {})
        tokens_in, tokens_out, cost_cents = extract_usage(response)

        KubikAi::Usage::Recorder.record!(
          operation: operation,
          model: model,
          input_tokens: tokens_in,
          output_tokens: tokens_out,
          estimated_cost_cents: cost_cents,
          status: status,
          error_message: error_message,
          subject: subject,
          metadata: metadata
        )
      end

      def extract_usage(response)
        return [nil, nil, DEFAULT_ESTIMATE_CENTS] if response.nil?

        input_tokens = nil
        output_tokens = nil
        cost_cents = DEFAULT_ESTIMATE_CENTS

        if response.respond_to?(:tokens)
          tokens = response.tokens
          input_tokens = tokens.input if tokens.respond_to?(:input)
          output_tokens = tokens.output if tokens.respond_to?(:output)
        end

        if response.respond_to?(:cost)
          cost = response.cost
          cost_cents = (cost.total.to_f * 100).ceil if cost.respond_to?(:total)
        end

        [input_tokens, output_tokens, cost_cents]
      rescue StandardError
        [nil, nil, DEFAULT_ESTIMATE_CENTS]
      end
    end
  end
end
