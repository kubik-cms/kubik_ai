# frozen_string_literal: true

begin
  require "active_admin"
rescue LoadError => e
  raise LoadError, "kubik_ai requires activeadmin. Add gem 'activeadmin' to your Gemfile. (#{e.message})"
end

require "ruby_llm"

require "kubik_ai/version"
require "kubik_ai/errors"
require "kubik_ai/configuration"

require "kubik_ai/context/providers/base"
require "kubik_ai/context/providers/site"
require "kubik_ai/context/providers/kubik_settings"
require "kubik_ai/context/providers/seo"
require "kubik_ai/metatag/content_fields"
require "kubik_ai/context/providers/metatagable_content"
require "kubik_ai/context/scopes"
require "kubik_ai/context/compiler"

require "kubik_ai/usage/limiter"
require "kubik_ai/usage/recorder"
require "kubik_ai/llm/credential_resolver"
require "kubik_ai/llm/gateway"
require "kubik_ai/media/tag_list"
require "kubik_ai/media/sync_stream"
require "kubik_ai/media/broadcaster"
require "kubik_ai/media/form_field_renderer"
require "kubik_ai/media/stale_recovery"
require "kubik_ai/media/panel_sync_attributes"
require "kubik_ai/media/status"
require "kubik_ai/media_upload_paths"
require "kubik_ai/media/analyzer"
require "kubik_ai/media/pending_applier"
require "kubik_ai/media/reinterpret_prompt"
require "kubik_ai/suggestions/field"
require "kubik_ai/suggestions/set"
require "kubik_ai/suggestions/media_upload_set"
require "kubik_ai/suggestions/metatag_set"
require "kubik_ai/metatag"
require "kubik_ai/active_admin/metatag_actions"
require "kubik_ai/media_upload_extension"
require "kubik_ai/media_upload_helper"
require "kubik_ai/metatag_admin_helper"

module KubikAi
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def config
      configuration
    end

    def configure
      yield(configuration)
    end

    def ensure_configuration
      configuration
    end
  end

  module Rails
    class Engine < ::Rails::Engine
      isolate_namespace KubikAi

      config.autoload_paths += Dir["#{root}/app/models"]
      config.autoload_paths += Dir["#{root}/app/jobs"]

      initializer "kubik_ai.metatag_lib" do
        require "kubik_ai/metatag"
      end

      initializer "kubik_ai.view_helpers" do
        ActiveSupport.on_load(:action_view) do
          include KubikAi::MediaUploadHelper
          include KubikAi::MetatagAdminHelper
        end
      end

      config.assets.precompile += %w[kubik_ai.scss kubik_ai/kubik_ai.es.js]

      initializer "kubik_ai.importmap_pin", after: :load_config_initializers do
        map = ::Rails.application.config.kubik_importmap
        next unless map

        js = root.join("app/assets/javascript/kubik_ai/kubik_ai.es.js")
        next unless js.exist?

        map.pin "@kubik-cms/kubik_ai", to: "kubik_ai/kubik_ai.es.js", preload: true
      end

      initializer :kubik_ai_default_providers do
        KubikAi.configure do |c|
          c.register_context_provider :site, KubikAi::Context::Providers::Site
          c.register_context_provider :kubik_settings, KubikAi::Context::Providers::KubikSettings
          c.register_context_provider :seo, KubikAi::Context::Providers::Seo
          c.suggestion_sets[:media_upload] = KubikAi::Suggestions::MediaUploadSet
          c.suggestion_sets[:metatag] = KubikAi::Suggestions::MetatagSet
        end
      end

      initializer :kubik_ai_metatag_actions do
        KubikAi::ActiveAdmin::MetatagActions
      end

      initializer :kubik_ai_active_admin do
        ::ActiveAdmin.application.load_paths += Dir[File.join(root, "lib", "active_admin")]
      end

      initializer :kubik_ai_media_hooks, before: :kubik_media_library_active_admin do
        require "kubik_ai/active_admin/media_upload_actions"
        KubikAi::ActiveAdmin::MediaUploadActions.register_hooks!
      end

      config.to_prepare do
        if defined?(Kubik::MediaUpload)
          Kubik::MediaUpload.include(KubikAi::MediaUploadExtension) unless Kubik::MediaUpload.include?(KubikAi::MediaUploadExtension)
        end

        next unless defined?(KubikAi::Metatag::StaleRecovery)

        KubikAi::Metatag::RuntimeState.singleton_class.prepend(
          Module.new do
            def fetch(record, focus: nil)
              KubikAi::Metatag::StaleRecovery.reconcile!(record, focus: focus)
              super
            end
          end
        )

        KubikAi::Metatag::SyncStream.singleton_class.prepend(
          Module.new do
            def render(record)
              KubikAi::Metatag::StaleRecovery.reconcile_all_focuses!(record)
              super
            end
          end
        )
      end
    end
  end
end
