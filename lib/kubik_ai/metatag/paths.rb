# frozen_string_literal: true

module KubikAi
  module Metatag
    module Paths
      module_function

      def panel_path(record, focus: nil)
        route_helper(record, "kubik_ai_metatag_panel_admin_#{singular_route_key(record)}_path", focus: focus)
      end

      def sync_path(record, focus: nil)
        route_helper(record, "kubik_ai_metatag_sync_admin_#{singular_route_key(record)}_path", focus: focus)
      end

      def suggest_path(record, focus: nil)
        route_helper(record, "kubik_ai_metatag_suggest_admin_#{singular_route_key(record)}_path", focus: focus)
      end

      def apply_path(record, focus: nil)
        route_helper(record, "kubik_ai_metatag_apply_admin_#{singular_route_key(record)}_path", focus: focus)
      end

      def discard_path(record, focus: nil)
        route_helper(record, "kubik_ai_metatag_discard_admin_#{singular_route_key(record)}_path", focus: focus)
      end

      def singular_route_key(record)
        record.model_name.singular_route_key
      end

      def route_helper(record, helper_name, focus: nil)
        path = ::Rails.application.routes.url_helpers.public_send(helper_name, record, only_path: true)
        return path if focus.blank?

        query = ::Rack::Utils.build_query(focus: focus)
        path.include?("?") ? "#{path}&#{query}" : "#{path}?#{query}"
      end
    end
  end
end
