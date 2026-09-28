# frozen_string_literal: true

module KubikAi
  class AnalyzeMediaUploadJob < ApplicationJob
    queue_as :default

    def perform(media_upload_id, operation: "analyze")
      upload = Kubik::MediaUpload.find_by(id: media_upload_id)
      return unless upload

      config = Kubik::AiConfiguration.instance
      unless config.enabled?
        KubikAi::Media::Status.fail!(upload, message: "AI is disabled in admin settings.")
        return
      end

      KubikAi::Media::Status.processing!(upload, operation: operation)

      unless KubikAi::Media::Analyzer.call(upload: upload, operation: operation)
        KubikAi::Media::Status.fail!(upload, message: "Could not analyze this image (missing file or invalid image).")
        return
      end

      upload.reload
      message = upload.additional_info.dig("kubik_ai", "pending").present? ?
                  "AI suggestions are ready for review." :
                  "AI analysis complete."
      KubikAi::Media::Status.complete!(upload, message: message)
    rescue KubikAi::SpendCapExceeded => e
      handle_failure(upload, e.message)
      ::Rails.logger.warn("[KubikAi] #{e.message}")
    rescue KubikAi::LlmError => e
      handle_failure(upload, e.message)
      ::Rails.logger.error("[KubikAi] Analyze failed for MediaUpload #{media_upload_id}: #{e.message}")
    rescue StandardError => e
      handle_failure(upload, e.message)
      ::Rails.logger.error("[KubikAi] Unexpected error for MediaUpload #{media_upload_id}: #{e.class}: #{e.message}")
    end

    private

    def handle_failure(upload, message)
      return unless upload

      KubikAi::Media::Status.fail!(upload, message: message)
    end
  end
end
