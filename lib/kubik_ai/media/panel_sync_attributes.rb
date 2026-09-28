# frozen_string_literal: true

module KubikAi
  module Media
    module PanelSyncAttributes
      module_function

      def for(upload)
        kubik_ai = upload.additional_info.fetch("kubik_ai", {})
        status = kubik_ai["status"].presence || "idle"
        return {} unless %w[queued processing].include?(status)

        {
          controller: "kubik-ai-panel-sync",
          kubik_ai_panel_sync_url_value: KubikAi::MediaUploadPaths.sync_path(upload),
          kubik_ai_panel_sync_panel_id_value: upload.id
        }
      end
    end
  end
end
