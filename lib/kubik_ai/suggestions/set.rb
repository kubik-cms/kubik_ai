# frozen_string_literal: true

module KubikAi
  module Suggestions
    class Set
      attr_reader :fields

      def initialize(fields)
        @fields = fields
      end

      def render(view, pending:, previous:, upload: nil, metatagable: nil)
        record = upload || metatagable
        fragments = fields.map do |field|
          view.render(
            partial: "kubik_ai/suggestions/field",
            locals: {
              field: field,
              record: record,
              pending: pending,
              previous: previous
            }
          )
        end
        view.safe_join(fragments)
      end
    end
  end
end
