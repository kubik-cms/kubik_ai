# frozen_string_literal: true

module KubikAi
  module Media
    module GalleryIndicator
      module_function

      def ai_active?(upload)
        status = upload.additional_info.to_h.dig("kubik_ai", "status").presence || "idle"
        %w[queued processing].include?(status)
      end

      def status_message(upload)
        upload.additional_info.to_h.dig("kubik_ai", "status_message").presence || "AI is working on this image…"
      end

      def can_restart?(upload)
        KubikAi::Media::RestartAnalysis.restartable?(upload)
      end

      def gallery_attention?(upload)
        ai_active?(upload) || upload.additional_info.to_h.dig("kubik_ai", "status") == "failed"
      end
    end
  end
end
