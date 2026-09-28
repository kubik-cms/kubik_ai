# frozen_string_literal: true

module KubikAi
  module MediaUploadPaths
    module_function

    def sync_path(upload)
      id = upload.respond_to?(:id) ? upload.id : upload
      ::Rails.application.routes.url_helpers.kubik_ai_sync_admin_kubik_media_upload_path(id)
    end
  end
end
