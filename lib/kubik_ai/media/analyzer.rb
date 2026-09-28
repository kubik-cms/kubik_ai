# frozen_string_literal: true

module KubikAi
  module Media
    class Analyzer
      def self.call(upload:, operation: :analyze)
        new(upload: upload, operation: operation).call
      end

      def initialize(upload:, operation:)
        @upload = upload
        @operation = operation.to_sym
      end

      def call
        return false unless @upload.image_data.present?

        path = image_path_for_llm
        return false unless path && File.exist?(path)

        @upload.reload
        kubik_ai_state = @upload.additional_info.fetch("kubik_ai", {})
        reinterpret_prompt = kubik_ai_state["current_reinterpret_prompt"].presence if @operation == :reinterpret
        context = KubikAi::Context::Compiler.compile
        media_state = @operation == :reinterpret ? KubikAi::Media::ReinterpretPrompt.media_state_for(@upload) : nil
        instructions = KubikAi::Media::ReinterpretPrompt.append_to_instructions(
          context,
          reinterpret_prompt,
          media_state: media_state
        )
        result = KubikAi::Llm::Gateway.analyze_image!(
          image_path: path,
          operation: operation_name,
          subject: @upload,
          instructions: instructions
        )

        apply_result!(result)
        true
      ensure
        @tempfile&.close!
      end

      private

      def operation_name
        @operation == :reinterpret ? "media_reinterpret" : "media_analyze"
      end

      def image_path_for_llm
        if @upload.respond_to?(:image) && @upload.image.present?
          attacher = @upload.image_attacher
          file = attacher.file
          return file.download if file.respond_to?(:download)

          storage = file.storage
          id = file.id
          path = storage.path(id) if storage.respond_to?(:path)
          return path if path && File.exist?(path)
        end

        nil
      rescue StandardError
        nil
      end

      def apply_result!(result)
        flags = Kubik::AiConfiguration.instance.feature_flags.with_indifferent_access
        info = @upload.additional_info.deep_dup
        kubik_ai = (info["kubik_ai"] || {}).deep_dup

        previous_alt = info["alt_text"].presence || info[:alt_text]
        previous_tags = @upload.respond_to?(:media_tag_list) ? @upload.media_tag_list : []

        if @operation == :reinterpret
          kubik_ai, consumed_prompt = KubikAi::Media::ReinterpretPrompt.consume!(kubik_ai)
          pending = {
            "alt_text" => result[:alt_text],
            "tags" => KubikAi::Media::TagList.normalize(result[:tags]),
            "notes" => result[:notes],
            "previous" => {
              "alt_text" => previous_alt,
              "tags" => previous_tags
            }
          }
          pending["user_prompt"] = consumed_prompt if consumed_prompt.present?
          kubik_ai["pending"] = pending
          kubik_ai["last_operation"] = "reinterpret"
          kubik_ai["version"] = 1
          info["kubik_ai"] = kubik_ai
          @upload.update!(additional_info: info)
          return
        else
          if flags.fetch(:auto_apply_alt_text, true)
            apply_alt_text!(info, result[:alt_text])
          end

          append_history!(kubik_ai, result)
          kubik_ai["pending"] = nil
          kubik_ai["last_operation"] = "analyze"
          kubik_ai["last_applied_at"] = Time.current.iso8601
        end

        kubik_ai["version"] = 1
        info["kubik_ai"] = kubik_ai
        @upload.additional_info = info

        if @operation != :reinterpret && flags.fetch(:auto_apply_tags, true)
          KubikAi::Media::TagList.assign_to_upload!(@upload, result[:tags])
        end

        @upload.save!
      end

      def apply_alt_text!(info, alt_text)
        return if alt_text.blank?

        info["alt_text"] = strip_html(alt_text)
      end

      def append_history!(kubik_ai, result)
        history = Array(kubik_ai["history"])
        history << {
          "at" => Time.current.iso8601,
          "alt_text" => result[:alt_text],
          "tags" => result[:tags],
          "notes" => result[:notes],
          "source" => "ai"
        }
        kubik_ai["history"] = history.last(20)
      end

      def strip_html(text)
        text.to_s.gsub(/<[^>]*>/, " ").squish
      end
    end
  end
end
