# frozen_string_literal: true

module Kubik
  class AiUsageEvent < ActiveRecord::Base
    self.table_name = "kubik_ai_usage_events"

    belongs_to :subject, polymorphic: true, optional: true

    scope :successful, -> { where(status: "success") }

    def self.period_range(period)
      case period.to_s
      when "daily"
        Time.current.beginning_of_day..Time.current.end_of_day
      else
        Time.current.beginning_of_month..Time.current.end_of_month
      end
    end

    def self.spent_in_period(period)
      successful.where(created_at: period_range(period)).sum(:estimated_cost_cents)
    end
  end
end
