# frozen_string_literal: true

module KubikAi
  module Metatag
    module PanelSyncAttributes
      module_function

      def for(record)
        state = RuntimeState.fetch(record)
        status = state["status"].presence || "idle"
        return {} unless %w[queued processing].include?(status)

        {
          controller: "kubik-ai-panel-sync",
          kubik_ai_panel_sync_url_value: Paths.sync_path(record),
          kubik_ai_panel_sync_panel_id_value: PanelDom.record_key(record)
        }
      end
    end
  end
end
