# frozen_string_literal: true

module KubikAi
  module Metatag
    module SyncStream
      module_function

      def render(record)
        return "" unless record&.persisted?

        ApplicationController.render(
          template: "kubik_ai/admin/metatag_sync",
          formats: [:turbo_stream],
          locals: { metatagable: record }
        )
      end
    end
  end
end
