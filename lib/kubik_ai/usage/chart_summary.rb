# frozen_string_literal: true

module KubikAi
  module Usage
    class ChartSummary
      SERIES_COLOR_VARS = (1..6).map { |i| "--kubik-chart-series-#{i}" }.freeze
      UNKNOWN_MODEL = "unknown"

      def self.call(**kwargs)
        new(**kwargs).call
      end

      def initialize(days: 30, time_zone: Time.zone, allowance_cents: nil)
        @days = days
        @time_zone = time_zone
        @allowance_cents = allowance_cents&.to_i
      end

      def call
        labels = date_labels
        grouped = fetch_grouped_sums
        models = grouped.values.flat_map(&:keys).uniq.sort

        datasets = models.map.with_index do |model, index|
          {
            label: model,
            color_var: SERIES_COLOR_VARS[index % SERIES_COLOR_VARS.size],
            data: labels.map { |date| value_for_chart(grouped.dig(date, model) || 0) }
          }
        end

        {
          labels: labels,
          datasets: datasets,
          series_keys: models
        }
      end

      private

      def range_start
        (@time_zone.now - (@days - 1).days).beginning_of_day
      end

      def range_end
        @time_zone.now.end_of_day
      end

      def date_labels
        start_date = range_start.to_date
        end_date = range_end.to_date
        (start_date..end_date).map(&:iso8601)
      end

      def fetch_grouped_sums
        result = Hash.new { |h, k| h[k] = {} }
        grouped_rows.each do |(date, model), cents|
          date_key = normalize_date_key(date)
          result[date_key][model_label(model)] = cents.to_i
        end
        result
      end

      def grouped_rows
        scope = Kubik::AiUsageEvent.successful.where(created_at: range_start..range_end)
        if postgres?
          scope.group(Arel.sql(sql_date_expression), :model).sum(:estimated_cost_cents)
        else
          scope.find_each.group_by { |event|
            [event.created_at.in_time_zone(@time_zone).to_date, event.model]
          }.transform_values { |events| events.sum(&:estimated_cost_cents) }
        end
      end

      def normalize_date_key(date)
        return date.iso8601 if date.is_a?(Date)

        date.to_s
      end

      def postgres?
        Kubik::AiUsageEvent.connection.adapter_name.match?(/postgres/i)
      end

      def sql_date_expression
        table = Kubik::AiUsageEvent.quoted_table_name
        zone = Kubik::AiUsageEvent.connection.quote(@time_zone.tzinfo.name)
        "(#{table}.created_at AT TIME ZONE 'UTC' AT TIME ZONE #{zone})::date"
      end

      def model_label(model)
        model.presence || UNKNOWN_MODEL
      end

      def value_for_chart(cents)
        if @allowance_cents.present? && @allowance_cents.positive?
          return cents_to_allowance_percent(cents)
        end

        (cents.to_i / 100.0).round(2)
      end

      def cents_to_allowance_percent(cents)
        ((cents.to_f / @allowance_cents) * 100).round(2)
      end
    end
  end
end
