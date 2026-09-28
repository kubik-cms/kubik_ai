# frozen_string_literal: true

module KubikAi
  module Usage
    class Recorder
      def self.record!(**attrs)
        Kubik::AiUsageEvent.create!(attrs)
      end
    end
  end
end
