# frozen_string_literal: true

module KubikAi
  module Usage
    class Limiter
      def self.check!(estimated_cents: 0)
        new.check!(estimated_cents: estimated_cents)
      end

      def check!(estimated_cents: 0)
        config = Kubik::AiConfiguration.instance
        cap = config.spend_cap_cents
        return if cap.blank? || cap.to_i <= 0

        spent = Kubik::AiUsageEvent.spent_in_period(config.spend_period)
        projected = spent + estimated_cents.to_i
        return if projected <= cap.to_i

        raise KubikAi::SpendCapExceeded,
              "AI spend cap exceeded (#{spent}c spent, cap #{cap}c #{config.spend_period})"
      end
    end
  end
end
