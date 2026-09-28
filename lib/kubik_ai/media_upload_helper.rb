# frozen_string_literal: true

module KubikAi
  module MediaUploadHelper
    def kubik_ai_media_upload_sync_path(upload)
      MediaUploadPaths.sync_path(upload)
    end

    def kubik_ai_media_upload_history_audit_rows(upload)
      history = Array(upload.additional_info.dig("kubik_ai", "history"))
      history.last(5).reverse.map do |entry|
        at_raw = entry["at"]
        at_time = begin
          Time.zone.parse(at_raw.to_s)
        rescue StandardError
          nil
        end
        tags = KubikAi::Media::TagList.normalize(entry["tags"])
        user_prompt = entry["user_prompt"].presence
        when_cell = if at_time
                      tag.time(l(at_time, format: :short), datetime: at_time.iso8601, title: at_time.iso8601)
                    else
                      tag.span(title: at_raw) { at_raw }
                    end

        {
          when: when_cell,
          alt_text: {
            content: entry["alt_text"].presence || tag.span(class: "kubik-panel-audit__empty") { "—" },
            title: entry["alt_text"]
          },
          tags: tags.any? ? tags.join(", ") : tag.span(class: "kubik-panel-audit__empty") { "—" },
          prompt: if user_prompt
                    { content: user_prompt, title: user_prompt }
                  else
                    tag.span(class: "kubik-panel-audit__empty") { "—" }
                  end
        }
      end
    end
  end
end
