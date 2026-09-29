# frozen_string_literal: true

module KubikAi
  class Configuration
    attr_accessor :active_admin_menu,
                  :active_admin_blocks,
                  :default_vision_model,
                  :default_text_model,
                  :prompt_version,
                  :plain_text_from_wysiwyg,
                  :metatag_broadcast_only

    def initialize
      @context_providers = {}
      @suggestion_sets = {}
      @active_admin_blocks = []
      @active_admin_menu = { label: "AI", priority: 95, parent: "Website" }
      @default_vision_model = "gemini-2.0-flash"
      @default_text_model = "gemini-2.0-flash"
      @prompt_version = "media_analyze_v1"
      @metatag_broadcast_only = false
    end

    def suggestion_sets
      @suggestion_sets
    end

    def register_context_provider(key, provider_class)
      @context_providers[key.to_sym] = provider_class
    end

    def context_providers
      @context_providers
    end

    def clear_context_providers!
      @context_providers = {}
    end
  end
end
