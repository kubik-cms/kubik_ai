# frozen_string_literal: true

module KubikAi
  module ActiveAdmin
    module LlmsTxtActions
      module_function

      def register!
        return unless defined?(KubikSettings)
        return unless defined?(Kubik::Setting)

        KubikSettings.configure do |config|
          config.add_active_admin_block do
            member_action :kubik_ai_generate_llms_txt, method: :post do
              KubikAi::GenerateLlmsTxtJob.perform_later(resource.id, instructions: params[:instructions])
              redirect_to admin_kubik_setting_path(resource),
                          notice: "llms.txt generation queued. Refresh to review draft."
            rescue KubikAi::FeatureDisabled => e
              redirect_to admin_kubik_setting_path(resource), alert: e.message
            end

            member_action :kubik_ai_apply_llms_txt, method: :post do
              draft = resource.settings_hash.with_indifferent_access[:llms_txt_ai_draft]
              if draft.blank?
                redirect_to admin_kubik_setting_path(resource), alert: "No AI draft to apply."
                next
              end

              resource.settings_hash = resource.settings_hash.merge(
                "llms_txt_body" => draft,
                "llms_txt_ai_draft" => nil
              )
              resource.save!
              Kubik::Discoverability.flush_caches! if defined?(Kubik::Discoverability)
              redirect_to admin_kubik_setting_path(resource), notice: "AI draft applied to llms.txt body."
            end
          end
        end
      end
    end
  end
end
