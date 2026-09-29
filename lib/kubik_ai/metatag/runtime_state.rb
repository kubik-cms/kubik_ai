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

      def self.cache_prefix(focus = nil)
        suffix = Focus.storage_suffix(focus)
        suffix ? "#{CACHE_PREFIX}/#{suffix}" : CACHE_PREFIX
      end

      def self.fetch(record, focus: nil)
        Store.read(record, cache_prefix(focus)) || DEFAULT_STATE.deep_dup
      end

      def self.queue!(record, operation: "suggest", focus: nil)
        patch!(record, {
          "status" => "queued",
          "status_message" => "Queued for AI meta suggestions…",
          "operation" => operation.to_s,
          "queued_at" => Time.current.iso8601
        }, focus: focus)
      end

      def self.processing!(record, operation: "suggest", focus: nil)
        patch!(record, {
          "status" => "processing",
          "status_message" => "AI is suggesting meta tags…",
          "operation" => operation.to_s,
          "started_at" => Time.current.iso8601
        }, focus: focus)
      end

      def self.complete!(record, message: nil, focus: nil)
        patch!(record, {
          "status" => "completed",
          "status_message" => message.presence || "AI meta suggestions are ready for review.",
          "completed_at" => Time.current.iso8601
        }, focus: focus)
      end

      def self.fail!(record, message:, focus: nil)
        patch!(record, {
          "status" => "failed",
          "status_message" => message.presence || "AI meta suggestions failed.",
          "failed_at" => Time.current.iso8601
        }, focus: focus)
      end

      def self.clear!(record, focus: nil)
        Store.delete(record, cache_prefix(focus))
        Broadcaster.broadcast!(record)
      end

      def self.patch!(record, attrs, focus: nil)
        prefix = cache_prefix(focus)
        state = (Store.read(record, prefix) || DEFAULT_STATE.deep_dup).merge(attrs.stringify_keys)
        Store.write(record, prefix, state)
        Broadcaster.broadcast!(record)
        state
      end
    end
  end
end
