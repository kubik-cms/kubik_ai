# frozen_string_literal: true

module KubikAi
  module Metatag
    module Paths
      module_function

      def panel_path(record)
        route_helper(record, "kubik_ai_metatag_panel_admin_#{singular_route_key(record)}_path")
      end

      def sync_path(record)
        route_helper(record, "kubik_ai_metatag_sync_admin_#{singular_route_key(record)}_path")
      end

      def suggest_path(record)
        route_helper(record, "kubik_ai_metatag_suggest_admin_#{singular_route_key(record)}_path")
      end

      def apply_path(record)
        route_helper(record, "kubik_ai_metatag_apply_admin_#{singular_route_key(record)}_path")
      end

      def discard_path(record)
        route_helper(record, "kubik_ai_metatag_discard_admin_#{singular_route_key(record)}_path")
      end

      def singular_route_key(record)
        record.model_name.singular_route_key
      end

      def route_helper(record, helper_name)
        ::Rails.application.routes.url_helpers.public_send(helper_name, record, only_path: true)
      end
    end
  end
end
