# frozen_string_literal: true

module KubikAi
  module Metatag
    module FormSyncFields
      module_function

      def for(record)
        tag = record.meta_tag
        return {} unless tag

        KubikAi::Metatag::PendingApplier::META_FIELDS.index_with do |field|
          tag.public_send(field).to_s
        end
      end
    end
  end
end
