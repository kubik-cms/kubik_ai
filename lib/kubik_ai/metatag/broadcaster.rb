# frozen_string_literal: true

module KubikAi
  module Metatag
    class Broadcaster
      def self.broadcast!(record)
        new(record).broadcast!
      end

      def initialize(record)
        @record = record
      end

      def broadcast!
        return unless @record&.persisted?
        return unless turbo_available?

        content = SyncStream.render(@record)
        return if content.blank?

        Turbo::StreamsChannel.broadcast_stream_to(stream_name, content: content)
      rescue StandardError => e
        ::Rails.logger.error(
          "[KubikAi] Turbo broadcast failed for #{@record.class.name} #{@record.id}: #{e.message}"
        )
      end

      def stream_name
        [@record, :kubik_ai_metatag]
      end

      private

      def turbo_available?
        defined?(Turbo::StreamsChannel)
      end
    end
  end
end
