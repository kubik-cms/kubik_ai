# frozen_string_literal: true

module KubikAi
  module Metatag
    class RuntimeState
      CACHE_PREFIX = "kubik_ai/metatag/runtime"
      DEFAULT_STATE = {
        "status" => "idle",
        "status_message" => nil,
        "operation" => nil
      }.freeze

      def self.fetch(record)
        Store.read(record, CACHE_PREFIX) || DEFAULT_STATE.deep_dup
      end

      def self.queue!(record, operation: "suggest")
        patch!(record, {
          "status" => "queued",
          "status_message" => "Queued for AI meta suggestions…",
          "operation" => operation.to_s,
          "queued_at" => Time.current.iso8601
        })
      end

      def self.processing!(record, operation: "suggest")
        patch!(record, {
          "status" => "processing",
          "status_message" => "AI is suggesting meta tags…",
          "operation" => operation.to_s,
          "started_at" => Time.current.iso8601
        })
      end

      def self.complete!(record, message: nil)
        patch!(record, {
          "status" => "completed",
          "status_message" => message.presence || "AI meta suggestions are ready for review.",
          "completed_at" => Time.current.iso8601
        })
      end

      def self.fail!(record, message:)
        patch!(record, {
          "status" => "failed",
          "status_message" => message.presence || "AI meta suggestions failed.",
          "failed_at" => Time.current.iso8601
        })
      end

      def self.clear!(record)
        Store.delete(record, CACHE_PREFIX)
        Broadcaster.broadcast!(record)
      end

      def self.patch!(record, attrs)
        state = fetch(record).merge(attrs.stringify_keys)
        Store.write(record, CACHE_PREFIX, state)
        Broadcaster.broadcast!(record)
        state
      end
    end
  end
end
