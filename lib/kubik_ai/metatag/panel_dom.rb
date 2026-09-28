# frozen_string_literal: true

module KubikAi
  module Metatag
    module PanelDom
      module_function

      def panel_id(record)
        "kubik_ai_panel_#{record_key(record)}"
      end

      def frame_id(record)
        "kubik_ai_frame_#{record_key(record)}"
      end

      def trigger_id(record)
        "kubik_ai_trigger_#{record_key(record)}"
      end

      def form_sync_id(record)
        "kubik_ai_metatag_form_sync_#{record_key(record)}"
      end

      def record_key(record)
        "#{record.model_name.singular}_#{record.id}"
      end
    end
  end
end
