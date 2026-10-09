# frozen_string_literal: true

module KubikAi
  module Media
    module RestartAnalysis
      RESTARTABLE_STATUSES = %w[queued processing failed].freeze
      ALLOWED_OPERATIONS = %w[analyze reinterpret].freeze

      module_function

      def call!(upload, operation: nil)
        upload = resolve_upload(upload)
        return false unless upload
        return false unless restartable?(upload)
        return false unless ai_enabled?

        op = normalize_operation(operation, upload)
        KubikAi::Media::Status.queue!(upload, operation: op)
        KubikAi::AnalyzeMediaUploadJob.perform_later(upload.id, operation: op)
        true
      end

      def restartable?(upload)
        upload = resolve_upload(upload)
        return false unless upload
        return false unless upload.aasm_state == "ready"
        return false unless upload.image_data.present?

        status = upload.additional_info.to_h.dig("kubik_ai", "status").presence || "idle"
        RESTARTABLE_STATUSES.include?(status)
      end

      def resolve_upload(upload)
        upload.is_a?(Kubik::MediaUpload) ? upload : Kubik::MediaUpload.find_by(id: upload)
      end

      def ai_enabled?
        defined?(Kubik::AiConfiguration) && Kubik::AiConfiguration.instance.enabled?
      rescue StandardError
        false
      end

      def normalize_operation(operation, upload)
        op = operation.presence || upload.additional_info.to_h.dig("kubik_ai", "operation").presence || "analyze"
        op = op.to_s
        ALLOWED_OPERATIONS.include?(op) ? op : "analyze"
      end
    end
  end
end
