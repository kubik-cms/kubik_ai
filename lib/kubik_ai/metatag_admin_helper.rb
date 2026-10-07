# frozen_string_literal: true

module KubikAi
  module MetatagAdminHelper
    # Second arg is positional so Arbre `helpers.` calls in .arb templates work (keywords are not forwarded).
    def kubik_ai_metatag_form_actions(metatagable, focus = nil)
      return unless defined?(KubikAi::ActiveAdmin::MetatagActions)
      return if metatagable.new_record?
      return unless defined?(Kubik::AiConfiguration) && Kubik::AiConfiguration.cached.enabled?
      return unless KubikAi::ResourceSettings.value_for_record(metatagable, :meta_tag_suggestions)
      return unless KubikAi::Metatag::Paths.panel_path_available?(metatagable)

      render partial: "kubik_ai/admin/metatag_trigger",
             locals: {
               metatagable: metatagable,
               focus: focus
             }
    end
  end
end
