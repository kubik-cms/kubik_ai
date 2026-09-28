# frozen_string_literal: true

module KubikAi
  module Metatag
    class SuggestionStore
      CACHE_PREFIX = "kubik_ai/metatag/pending"

      def self.fetch(record)
        Store.read(record, CACHE_PREFIX)
      end

      def self.store!(record, payload)
        Store.write(record, CACHE_PREFIX, payload)
      end

      def self.clear!(record)
        Store.delete(record, CACHE_PREFIX)
      end
    end
  end
end
