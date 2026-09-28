# frozen_string_literal: true

module KubikAi
  module Media
    module SyncStream
      module_function

      def render(upload)
        upload = upload.is_a?(Kubik::MediaUpload) ? upload : Kubik::MediaUpload.find_by(id: upload)
        return "" unless upload

        ApplicationController.render(
          template: "kubik_ai/admin/media_upload_sync",
          formats: [:turbo_stream],
          locals: { upload: upload.reload }
        )
      end
    end
  end
end
