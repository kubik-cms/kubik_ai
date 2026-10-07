# frozen_string_literal: true

module KubikAi
  module ResourceSettings
    module_function

    def media_value(key)
      resolve(:media, key, -> { Kubik::AiConfiguration.instance.public_send(key) })
    end

    def value_for_record(record, key)
      resource_key = resource_key_for(record)
      fallback = -> { Kubik::AiConfiguration.instance.public_send(key) }
      return fallback.call unless resource_key

      resolve(resource_key, key, fallback)
    end

    def resource_key_for(record)
      return unless defined?(KubikSettings::ResourceResolver)

      KubikSettings::ResourceResolver.resource_key_for(record)
    end

    def context_for_scopes(resource_key, scopes)
      Array(scopes).filter_map do |scope|
        text = nil
        if resource_key && defined?(KubikSettings::ResourceResolver)
          text = KubikSettings::ResourceResolver.context_for_scope(resource_key, scope)
        end
        if text.blank? && defined?(Kubik::AiConfiguration)
          text = Kubik::AiConfiguration.instance.context_instructions[scope].to_s.strip
        end
        next if text.blank?

        "## #{KubikAi::Context::Scopes.heading(scope)}\n#{text}"
      end
    end

    def resolve(resource_key, key, fallback)
      if defined?(KubikSettings::ResourceResolver) && KubikSettings::ResourceResolver.registered?(resource_key)
        value = KubikSettings::ResourceResolver.get(resource_key, key)
        return value unless value.nil?
      end
      fallback.call
    rescue StandardError
      fallback.call
    end
  end
end
