# frozen_string_literal: true

module KubikAi
  module Media
    class Broadcaster
      def self.broadcast!(upload)
        new(upload).broadcast!
      end

      def initialize(upload)
        @upload = upload.is_a?(Kubik::MediaUpload) ? upload : Kubik::MediaUpload.find_by(id: upload)
      end

      def broadcast!
        return unless @upload
        return unless turbo_available?

        content = SyncStream.render(@upload)
        return if content.blank?

        Turbo::StreamsChannel.broadcast_stream_to(stream_name, content: content)
      rescue StandardError => e
        ::Rails.logger.error("[KubikAi] Turbo broadcast failed for MediaUpload #{@upload.id}: #{e.message}")
      end

      def stream_name
        [@upload, :kubik_ai]
      end

      private

      def turbo_available?
        defined?(Turbo::StreamsChannel)
      end
    end
  end
end
