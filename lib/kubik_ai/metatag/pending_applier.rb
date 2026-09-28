# frozen_string_literal: true

module KubikAi
  module Metatag
    class PendingApplier
      META_FIELDS = %w[
        title_tag meta_description og_title og_description og_type
        twitter_title twitter_description twitter_card_type
      ].freeze

      def self.apply!(record, overrides: {})
        new(record).apply!(overrides: overrides)
      end

      def self.discard!(record)
        new(record).discard!
      end

      def initialize(record)
        @record = record
      end

      def apply!(overrides: {})
        pending = SuggestionStore.fetch(@record)
        return false unless pending

        merged = pending.merge(overrides.stringify_keys)
        tag = @record.meta_tag || @record.build_meta_tag

        META_FIELDS.each do |field|
          next unless merged.key?(field)

          tag.public_send("#{field}=", merged[field])
        end

        tag.save!
        SuggestionStore.clear!(@record)
        Broadcaster.broadcast!(@record)
        true
      end

      def discard!
        cleared = SuggestionStore.fetch(@record).present?
        SuggestionStore.clear!(@record)
        Broadcaster.broadcast!(@record) if cleared
        cleared
      end
    end
  end
end
