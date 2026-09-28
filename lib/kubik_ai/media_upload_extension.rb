# frozen_string_literal: true

module KubikAi
  module MediaUploadExtension
    extend ActiveSupport::Concern

    included do
      after_commit :kubik_ai_enqueue_analysis, if: :kubik_ai_should_enqueue?
    end

    def kubik_ai_should_enqueue?
      return false unless defined?(Kubik::AiConfiguration)
      return false unless image_data.present?
      return false unless aasm_state == "ready"
      return false unless kubik_ai_state_changed_to_ready?

      config = Kubik::AiConfiguration.instance
      return false unless config.enabled?

      flags = config.feature_flags.with_indifferent_access
      flags.fetch(:auto_analyze_on_upload, true)
    rescue StandardError
      false
    end

    def kubik_ai_enqueue_analysis
      KubikAi::Media::Status.queue!(self, operation: :analyze)
      KubikAi::AnalyzeMediaUploadJob.perform_later(id, operation: "analyze")
    end

    private

    def kubik_ai_state_changed_to_ready?
      return false unless saved_change_to_aasm_state?

      saved_change_to_aasm_state.last == "ready"
    end
  end
end
