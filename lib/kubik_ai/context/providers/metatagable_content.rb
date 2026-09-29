# frozen_string_literal: true

module KubikAi
  module Context
    module Providers
      class MetatagableContent < Base
        DEFAULT_LIMIT = 8_000

        def initialize(metatagable: nil, limit: DEFAULT_LIMIT)
          @metatagable = metatagable
          @limit = limit
        end

        def available?
          @metatagable.present? && extract_text(@metatagable).present?
        end

        def heading
          "Page content"
        end

        def to_prompt
          extract_text(@metatagable).truncate(@limit)
        end

        private

        def extract_text(record)
          KubikAi::Metatag::ContentExtractor.extract(record)
        end
      end
    end
  end
end
