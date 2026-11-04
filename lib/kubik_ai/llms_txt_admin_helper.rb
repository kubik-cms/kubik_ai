# frozen_string_literal: true

module KubikAi
  module LlmsTxtAdminHelper
    def kubik_llms_txt_form_actions(setting)
      return unless setting.is_a?(Kubik::Setting)
      return unless Kubik::AiConfiguration.instance.enabled && Kubik::AiConfiguration.instance.llms_txt_suggestions

      link_to(
        "Generate llms.txt with AI",
        kubik_ai_generate_llms_txt_admin_kubik_setting_path(setting),
        method: :post,
        class: "button",
        data: { turbo: false }
      )
    end
  end
end
