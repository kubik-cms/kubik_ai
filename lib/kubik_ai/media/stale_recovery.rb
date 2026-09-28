# frozen_string_literal: true

module KubikAi
  module Media
    module StaleRecovery
      QUEUED_STALE_AFTER = 5.minutes
      PROCESSING_STALE_AFTER = 15.minutes

      module_function

      def reconcile!(upload, context: :full)
        upload = upload.is_a?(Kubik::MediaUpload) ? upload : Kubik::MediaUpload.find_by(id: upload)
        return unless upload

        kubik_ai = upload.additional_info.fetch("kubik_ai", {})
        status = kubik_ai["status"].presence
        return unless %w[queued processing].include?(status)

        anchor = parse_time(kubik_ai["started_at"]) || parse_time(kubik_ai["queued_at"])
        return unless anchor

        case status
        when "queued"
          reconcile_stale_queued!(upload, kubik_ai, anchor) if context == :full
        when "processing"
          reconcile_stale_processing!(upload, anchor)
        end
      end

      def reconcile_stale_queued!(upload, kubik_ai, queued_at)
        return if queued_at > QUEUED_STALE_AFTER.ago

        requeued_at = parse_time(kubik_ai["recovery_requeued_at"])
        return if requeued_at && requeued_at > QUEUED_STALE_AFTER.ago

        operation = kubik_ai["operation"].presence || "analyze"
        ::Rails.logger.info(
          "[KubikAi] Re-enqueueing stale queued analysis for MediaUpload #{upload.id} (#{operation})"
        )
        KubikAi::AnalyzeMediaUploadJob.perform_later(upload.id, operation: operation)
        touch_recovery_requeue!(upload, operation: operation)
      end

      def reconcile_stale_processing!(upload, started_at)
        return if started_at > PROCESSING_STALE_AFTER.ago

        ::Rails.logger.warn("[KubikAi] Marking stale processing as failed for MediaUpload #{upload.id}")
        Status.fail!(
          upload,
          message: "AI analysis timed out or was interrupted. Use Reinterpret with AI to try again."
        )
      end

      def parse_time(value)
        return if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end

      def touch_recovery_requeue!(upload, operation:)
        info = upload.additional_info.deep_dup
        kubik_ai = (info["kubik_ai"] || {}).deep_dup
        kubik_ai["status"] = "queued"
        kubik_ai["status_message"] = "Queued for AI analysis…"
        kubik_ai["operation"] = operation.to_s
        kubik_ai["queued_at"] = Time.current.iso8601
        kubik_ai["recovery_requeued_at"] = Time.current.iso8601
        kubik_ai["version"] = 1
        info["kubik_ai"] = kubik_ai
        upload.update!(additional_info: info)
        Broadcaster.broadcast!(upload)
      end
      private_class_method :parse_time, :reconcile_stale_queued!, :reconcile_stale_processing!, :touch_recovery_requeue!
    end
  end
end
