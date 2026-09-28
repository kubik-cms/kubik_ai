# frozen_string_literal: true

module KubikAi
  module Media
    class Status
      STATUSES = %w[idle queued processing completed failed].freeze

      def self.queue!(upload, operation:)
        new(upload).queue!(operation: operation)
      end

      def self.processing!(upload, operation:)
        new(upload).processing!(operation: operation)
      end

      def self.complete!(upload, message: nil)
        new(upload).complete!(message: message)
      end

      def self.fail!(upload, message:)
        new(upload).fail!(message: message)
      end

      def initialize(upload)
        @upload = upload
      end

      def queue!(operation:)
        patch_kubik_ai!(
          "status" => "queued",
          "status_message" => "Queued for AI analysis…",
          "operation" => operation.to_s,
          "queued_at" => Time.current.iso8601
        )
      end

      def processing!(operation:)
        patch_kubik_ai!(
          "status" => "processing",
          "status_message" => "AI is analyzing this image…",
          "operation" => operation.to_s,
          "started_at" => Time.current.iso8601
        )
      end

      def complete!(message: nil)
        patch_kubik_ai!(
          "status" => "completed",
          "status_message" => message.presence || "AI analysis complete.",
          "completed_at" => Time.current.iso8601
        )
      end

      def fail!(message:)
        patch_kubik_ai!(
          "status" => "failed",
          "status_message" => message.presence || "AI analysis failed.",
          "failed_at" => Time.current.iso8601,
          "pending" => nil
        )
      end

      private

      def patch_kubik_ai!(attrs)
        info = @upload.additional_info.deep_dup
        kubik_ai = (info["kubik_ai"] || {}).deep_dup
        kubik_ai.merge!(attrs)
        kubik_ai["version"] = 1
        info["kubik_ai"] = kubik_ai
        @upload.update!(additional_info: info)
        Broadcaster.broadcast!(@upload)
      end
    end
  end
end
