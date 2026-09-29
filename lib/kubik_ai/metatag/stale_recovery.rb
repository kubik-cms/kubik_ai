# frozen_string_literal: true

module KubikAi
  module Metatag
    # Clears queued/processing UI when a job never finishes (worker crash, cable miss, etc.).
    module StaleRecovery
      module_function

      def stale_after
        seconds = ENV.fetch("KUBIK_AI_METATAG_STALE_SECONDS", "10").to_i
        seconds.positive? ? seconds.seconds : 10.seconds
      end

      def reconcile!(record, focus: nil)
        return unless record&.persisted?

        prefix = RuntimeState.cache_prefix(focus)
        state = Store.read(record, prefix) || RuntimeState::DEFAULT_STATE.deep_dup
        status = state["status"].presence
        return unless %w[queued processing].include?(status)

        anchor = parse_time(state["started_at"]) || parse_time(state["queued_at"])
        return unless anchor
        return if anchor > stale_after.ago

        ::Rails.logger.warn(
          "[KubikAi] Clearing stale metatag #{status} for #{record.class.name} #{record.id} focus=#{focus.inspect}"
        )
        RuntimeState.clear!(record, focus: focus)
        true
      end

      def reconcile_all_focuses!(record)
        reconciled = reconcile!(record, focus: nil)
        Focus.all.each do |focus|
          reconciled = true if reconcile!(record, focus: focus)
        end
        reconciled
      end

      def parse_time(value)
        return if value.blank?

        Time.zone.parse(value.to_s)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
