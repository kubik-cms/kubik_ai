# frozen_string_literal: true

module KubikAi
  class Error < StandardError; end

  class SpendCapExceeded < Error; end

  class ConfigurationError < Error; end

  class LlmError < Error; end

  class FeatureDisabled < Error; end
end
