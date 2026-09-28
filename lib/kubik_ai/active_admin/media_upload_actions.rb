# frozen_string_literal: true

module KubikAi
  module ActiveAdmin
    module MediaUploadActions
      module_function

      def register_hooks!
        return if @hooks_registered

        @hooks_registered = true

        KubikMediaLibrary.configure do |config|
          config.active_admin_customize do
            member_action :kubik_ai_panel, method: :get do
              KubikAi::Media::StaleRecovery.reconcile!(resource)
              resource.reload

              respond_to do |format|
                format.html do
                  if turbo_frame_request?
                    render "kubik_ai/admin/kubik_ai_panel",
                           locals: { upload: resource },
                           layout: false
                  else
                    redirect_to edit_admin_kubik_media_upload_path(resource, only_path: true)
                  end
                end
              end
            end

            member_action :kubik_ai_sync, method: :get do
              KubikAi::Media::StaleRecovery.reconcile!(resource, context: :poll)
              resource.reload

              render template: "kubik_ai/admin/media_upload_sync",
                     formats: [:turbo_stream],
                     locals: { upload: resource }
            end

            member_action :kubik_ai_reinterpret, method: :post do
              prompt = params.dig(:kubik_ai, :additional_prompt).to_s.strip
              KubikAi::Media::ReinterpretPrompt.store!(resource, prompt)
              KubikAi::Media::Status.queue!(resource, operation: :reinterpret)
              KubikAi::AnalyzeMediaUploadJob.perform_later(resource.id, operation: "reinterpret")
              resource.reload

              render template: "kubik_ai/admin/media_upload_sync",
                     formats: [:turbo_stream],
                     locals: { upload: resource, attach_frame_sync: true }
            end

            member_action :kubik_ai_apply_pending, method: :post do
              overrides = params.fetch(:kubik_ai_pending, {}).permit(:alt_text, :media_tag_list)
              applied = KubikAi::Media::PendingApplier.apply!(resource, overrides: overrides.to_h)
              resource.reload if applied

              if applied
                render template: "kubik_ai/admin/media_upload_sync",
                       formats: [:turbo_stream],
                       locals: { upload: resource }
              else
                head :unprocessable_entity
              end
            end

            member_action :kubik_ai_discard_pending, method: :post do
              discarded = KubikAi::Media::PendingApplier.discard!(resource)
              resource.reload if discarded

              if discarded
                render template: "kubik_ai/admin/media_upload_sync",
                       formats: [:turbo_stream],
                       locals: { upload: resource }
              else
                head :unprocessable_entity
              end
            end

          end
        end
      end
    end
  end
end
