# frozen_string_literal: true

module KubikAi
  module Media
    module ReinterpretPrompt
      module_function

      def store!(upload, prompt)
        text = prompt.to_s.strip
        info = upload.additional_info.deep_dup
        kubik_ai = (info["kubik_ai"] || {}).deep_dup
        kubik_ai["current_reinterpret_prompt"] = text.presence
        kubik_ai["last_additional_prompt"] = text if text.present?
        info["kubik_ai"] = kubik_ai
        upload.update!(additional_info: info)
      end

      def consume!(kubik_ai)
        kubik_ai = kubik_ai.deep_dup
        prompt = kubik_ai.delete("current_reinterpret_prompt")
        [kubik_ai, prompt]
      end

      def media_state_for(upload)
        info = upload.additional_info
        alt = info["alt_text"].presence || info[:alt_text].presence
        tags = upload.respond_to?(:media_tag_list) ? KubikAi::Media::TagList.normalize(upload.media_tag_list) : []

        lines = []
        lines << "Alt text currently saved on this media item: #{alt}" if alt.present?
        lines << "Tags currently saved on this media item: #{tags.join(', ')}" if tags.any?
        lines.join("\n")
      end

      def append_to_instructions(base_instructions, prompt, media_state: nil)
        sections = [base_instructions]
        sections << "## Current media record\n#{media_state.strip}" if media_state.present?
        if prompt.present?
          sections << <<~INSTRUCTIONS.strip
            ## Additional instructions from editor (highest priority)
            Follow these for this reinterpretation even if they differ from site context or the current saved values.
            Apply them to both suggested alt text and tags unless the editor asks to change only one field.

            #{prompt.strip}
          INSTRUCTIONS
        end
        sections.compact.join("\n\n")
      end
    end
  end
end
