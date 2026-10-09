# frozen_string_literal: true

module KubikAi
  module Media
    module MissedAnalysis
      module_function

      def enqueue_if_eligible!(upload)
        upload = upload.is_a?(Kubik::MediaUpload) ? upload : Kubik::MediaUpload.find_by(id: upload)
        return false unless upload
        return false unless eligible?(upload)

        KubikAi::Media::Status.queue!(upload, operation: :analyze)
        KubikAi::AnalyzeMediaUploadJob.perform_later(upload.id, operation: "analyze")
        true
      end

      def eligible?(upload)
        return false unless upload.aasm_state == "ready"
        return false unless upload.image_data.present?
        return false unless defined?(Kubik::AiConfiguration) && Kubik::AiConfiguration.instance.enabled?
        return false unless KubikAi::ResourceSettings.media_value(:auto_analyze_on_upload)

        kubik_ai = upload.additional_info.fetch("kubik_ai", {})
        return true if kubik_ai.blank?

        status = kubik_ai["status"].presence
        return false if %w[queued processing completed].include?(status)
        return false if status == "failed"

        status.blank? || status == "idle"
      rescue StandardError
        false
      end
    end
  end
end
