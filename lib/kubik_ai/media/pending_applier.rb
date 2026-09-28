# frozen_string_literal: true

module KubikAi
  module Media
    class PendingApplier
      def self.apply!(upload, overrides: {})
        new(upload).apply!(overrides: overrides)
      end

      def self.discard!(upload)
        new(upload).discard!
      end

      def initialize(upload)
        @upload = upload
      end

      def apply!(overrides: {})
        pending = pending_data
        return false unless pending

        pending = merge_overrides(pending, overrides)

        info = @upload.additional_info.deep_dup
        kubik_ai = (info["kubik_ai"] || {}).deep_dup

        if pending.key?("alt_text")
          info["alt_text"] = strip_html(pending["alt_text"])
        end

        if overrides.key?(:media_tag_list) || overrides.key?("media_tag_list") || pending.key?("tags")
          normalized_tags = KubikAi::Media::TagList.normalize(pending["tags"])
          assign_tags!(normalized_tags)
          pending = pending.merge("tags" => normalized_tags)
        end

        append_history!(kubik_ai, pending)
        kubik_ai["pending"] = nil
        kubik_ai["last_applied_at"] = Time.current.iso8601
        kubik_ai["last_operation"] = "reinterpret_applied"
        info["kubik_ai"] = kubik_ai

        @upload.additional_info = info
        @upload.save!
        true
      end

      def discard!
        info = @upload.additional_info.deep_dup
        kubik_ai = (info["kubik_ai"] || {}).deep_dup
        return false unless kubik_ai["pending"].present?

        kubik_ai["pending"] = nil
        info["kubik_ai"] = kubik_ai
        @upload.update!(additional_info: info)
        true
      end

      private

      def pending_data
        @upload.additional_info.dig("kubik_ai", "pending")
      end

      def append_history!(kubik_ai, pending)
        history = Array(kubik_ai["history"])
        entry = {
          "at" => Time.current.iso8601,
          "alt_text" => pending["alt_text"],
          "tags" => pending["tags"],
          "notes" => pending["notes"],
          "source" => "ai_reinterpret"
        }
        entry["user_prompt"] = pending["user_prompt"] if pending["user_prompt"].present?
        history << entry
        kubik_ai["history"] = history.last(20)
      end

      def strip_html(text)
        text.to_s.gsub(/<[^>]*>/, " ").squish
      end

      def merge_overrides(pending, overrides)
        merged = pending.deep_dup
        data = overrides.with_indifferent_access
        merged["alt_text"] = data[:alt_text] if data.key?(:alt_text)
        if data.key?(:media_tag_list)
          merged["tags"] = KubikAi::Media::TagList.normalize(data[:media_tag_list])
        end
        merged
      end

      def assign_tags!(tags)
        return unless @upload.respond_to?(:set_tag_list_on)

        @upload.set_tag_list_on(:media_tags, tags)
      end
    end
  end
end
