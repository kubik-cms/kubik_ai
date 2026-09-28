# frozen_string_literal: true

module Kubik
  class AiConfiguration < ActiveRecord::Base
    self.table_name = "kubik_ai_configurations"

    encrypts :provider_credentials

    SPEND_PERIODS = %w[daily monthly].freeze
    CREDENTIAL_SOURCES = %w[env database].freeze
    FEATURE_FLAG_KEYS = %i[
      auto_analyze_on_upload
      auto_apply_alt_text
      auto_apply_tags
      meta_tag_suggestions
      seo_keyword_emphasis
      prefer_no_faces
      tag_vocabulary_hints
    ].freeze

    FEATURE_FLAG_KEYS.each do |key|
      define_method(key) do
        feature_flags.with_indifferent_access[key]
      end

      define_method("#{key}=") do |value|
        cast_value = key == :tag_vocabulary_hints ? value : ActiveModel::Type::Boolean.new.cast(value)
        self.feature_flags = feature_flags.merge(key.to_s => cast_value)
      end
    end

    after_commit :flush_cache

    def self.instance
      first_or_create!(singleton_guard: 1) do |record|
        record.enabled = false
        record.vision_model = KubikAi.config.default_vision_model
        record.credential_source = "env"
        record.spend_period = "monthly"
        record.feature_flags = default_feature_flags
        record.provider_credentials = {}
      end
    end

    def self.default_feature_flags
      {
        auto_analyze_on_upload: true,
        auto_apply_alt_text: true,
        auto_apply_tags: true,
        meta_tag_suggestions: true,
        seo_keyword_emphasis: true,
        prefer_no_faces: false,
        tag_vocabulary_hints: ""
      }
    end

    def feature_flags
      stored = super.presence || {}
      self.class.default_feature_flags.stringify_keys.merge(stored.stringify_keys)
    end

    def to_s
      "AI configuration"
    end

    def self.cached
      Rails.cache.fetch("kubik/ai_configuration") { instance }
    end

    private

    def flush_cache
      Rails.cache.delete("kubik/ai_configuration")
    end
  end
end
