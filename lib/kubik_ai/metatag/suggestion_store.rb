# frozen_string_literal: true

module KubikAi
  module Metatag
    class SuggestionStore
      CACHE_PREFIX = "kubik_ai/metatag/pending"

      def self.cache_prefix(focus = nil)
        suffix = Focus.storage_suffix(focus)
        suffix ? "#{CACHE_PREFIX}/#{suffix}" : CACHE_PREFIX
      end

      def self.fetch(record, focus: nil)
        Store.read(record, cache_prefix(focus))
      end

      def self.store!(record, payload, focus: nil)
        Store.write(record, cache_prefix(focus), payload)
      end

      def self.clear!(record, focus: nil)
        Store.delete(record, cache_prefix(focus))
      end
    end
  end
end
