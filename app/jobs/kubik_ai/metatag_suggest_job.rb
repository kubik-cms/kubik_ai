# frozen_string_literal: true

require "kubik_ai/metatag"

module KubikAi
  class MetatagSuggestJob < ApplicationJob
    queue_as :default

    ruby2_keywords def perform(record_class_name, record_id, focus = nil, instructions = nil)
      @focus = focus
      @instructions = instructions
      record = record_class_name.constantize.find_by(id: record_id)
      return unless record

      KubikAi::Metatag::RuntimeState.processing!(record, focus: @focus)
      KubikAi::Metatag::Suggestor.call(
        metatagable: record,
        broadcast: false,
        focus: @focus,
        instructions: @instructions
      )
      KubikAi::Metatag::RuntimeState.complete!(
        record,
        message: "AI meta suggestions are ready for review.",
        focus: @focus
      )
    rescue KubikAi::FeatureDisabled => e
      handle_failure(record, e.message)
    rescue KubikAi::SpendCapExceeded => e
      handle_failure(record, e.message)
      ::Rails.logger.warn("[KubikAi] #{e.message}")
    rescue KubikAi::LlmError => e
      handle_failure(record, e.message)
      ::Rails.logger.error("[KubikAi] Metatag suggest failed for #{record_class_name} #{record_id}: #{e.message}")
    rescue StandardError => e
      handle_failure(record, e.message)
      ::Rails.logger.error(
        "[KubikAi] Unexpected metatag error for #{record_class_name} #{record_id}: #{e.class}: #{e.message}"
      )
    end

    private

    def handle_failure(record, message)
      return unless record

      KubikAi::Metatag::RuntimeState.fail!(record, message: message, focus: @focus)
    end
  end
end
