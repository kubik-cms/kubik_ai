# frozen_string_literal: true

module KubikAi
  module ActiveAdmin
    module MetatagActions
      extend ActiveSupport::Concern

      def self.included(base)
        # Meta AI trigger belongs on the Meta tab only (not the page title bar).
        base.config.remove_action_item(:kubik_ai_metatag)

        base.send(:member_action, :kubik_ai_metatag_panel, method: :get) do
          respond_to do |format|
            format.html do
              if turbo_frame_request?
                render "kubik_ai/admin/metatag_panel",
                       locals: { metatagable: resource },
                       layout: false
              else
                redirect_to resource_path(resource, only_path: true)
              end
            end
          end
        end

        base.send(:member_action, :kubik_ai_metatag_sync, method: :get) do
          render template: "kubik_ai/admin/metatag_sync",
                 formats: [:turbo_stream],
                 locals: { metatagable: resource }
        end

        base.send(:member_action, :kubik_ai_metatag_suggest, method: :post) do
          KubikAi::Metatag::RuntimeState.queue!(resource)
          KubikAi::MetatagSuggestJob.perform_later(resource.class.name, resource.id)

          respond_to do |format|
            format.html do
              redirect_back fallback_location: resource_path(resource), notice: "AI meta suggestions queued."
            end
            format.turbo_stream do
              render template: "kubik_ai/admin/metatag_sync",
                     formats: [:turbo_stream],
                     locals: { metatagable: resource, attach_frame_sync: true }
            end
          end
        rescue KubikAi::FeatureDisabled => e
          respond_to do |format|
            format.html { redirect_back fallback_location: resource_path(resource), alert: e.message }
            format.turbo_stream { head :unprocessable_entity }
          end
        end

        base.send(:member_action, :kubik_ai_metatag_apply, method: :post) do
          overrides = params.fetch(:kubik_ai_pending, {}).permit(
            *KubikAi::Metatag::PendingApplier::META_FIELDS
          )
          applied = KubikAi::Metatag::PendingApplier.apply!(resource, overrides: overrides.to_h)
          resource.reload if applied

          if applied
            render template: "kubik_ai/admin/metatag_sync",
                   formats: [:turbo_stream],
                   locals: { metatagable: resource, sync_main_form: true }
          else
            head :unprocessable_entity
          end
        end

        base.send(:member_action, :kubik_ai_metatag_discard, method: :post) do
          discarded = KubikAi::Metatag::PendingApplier.discard!(resource)

          if discarded
            render template: "kubik_ai/admin/metatag_sync",
                   formats: [:turbo_stream],
                   locals: { metatagable: resource }
          else
            head :unprocessable_entity
          end
        end

      end

      def self.register!(resource_class)
        ActiveAdmin.register resource_class do
          include MetatagActions unless included_modules.include?(MetatagActions)
        end
      end
    end
  end
end
