# frozen_string_literal: true

# Loaded via ActiveAdmin load_paths (see KubikAi::Engine) so controllers reload in development.
MEDIA_RESOURCE_AI_KEYS = %i[
  auto_analyze_on_upload auto_apply_alt_text auto_apply_tags tag_vocabulary_hints
].freeze

ActiveAdmin.register Kubik::AiConfiguration do
  menu_options = KubikAi.config.active_admin_menu || {}
  menu(**menu_options) if menu_options.present?

  actions :all, except: %i[create new destroy]

  permit_params :enabled,
                :vision_model,
                :site_context,
                :spend_cap_cents,
                :spend_period,
                :credential_source,
                *Kubik::AiConfiguration::FEATURE_FLAG_KEYS,
                *Kubik::AiConfiguration::CONTEXT_INSTRUCTION_KEYS.map { |key| "context_#{key}" },
                provider_credentials: %i[openai_api_key anthropic_api_key gemini_api_key]

  controller do
    actions :all, except: %i[create new destroy]

    def find_resource
      Kubik::AiConfiguration.instance
    end

    def index
      redirect_to admin_kubik_ai_configuration_path(1)
    end

    def update
      merge_provider_credentials_into_params
      super
    end

    def merge_provider_credentials_into_params
      raw = params[active_admin_config.param_key]
      return unless raw

      incoming = (raw[:provider_credentials] || {}).to_unsafe_h
      existing = resource.provider_credentials || {}
      raw[:provider_credentials] = existing.merge(incoming).compact_blank
    end
  end

  member_action :test_llm_connection, method: :post do
    KubikAi::Llm::Gateway.ping!
    redirect_to admin_kubik_ai_configuration_path(resource), notice: "Connection successful"
  rescue KubikAi::SpendCapExceeded => e
    redirect_to admin_kubik_ai_configuration_path(resource), alert: e.message
  rescue KubikAi::LlmError => e
    redirect_to admin_kubik_ai_configuration_path(resource), alert: e.message
  end

  action_item :test_llm_connection, only: :edit do
    link_to "Test connection",
            test_llm_connection_admin_kubik_ai_configuration_path(resource),
            method: :post
  end

  show do
    tabs do
      tab "General" do
        attributes_table_for resource do
          row :enabled
          row :vision_model
          row :site_context
          row :credential_source
        end
      end

      tab "AI instructions" do
        attributes_table_for resource do
          row :site_context
          Kubik::AiConfiguration::CONTEXT_INSTRUCTION_KEYS.each do |key|
            next if key == :media

            row KubikAi::Context::Scopes.heading(key) do
              simple_format resource.context_instructions[key]
            end
          end
        end
      end

      tab "Features" do
        attributes_table_for resource do
          resource.feature_flags.each do |key, value|
            next if MEDIA_RESOURCE_AI_KEYS.include?(key.to_sym)

            row key.to_s.humanize do
              value
            end
          end
        end
      end

      tab "Limits & usage" do
        attributes_table_for resource do
          row "Token usage (this period)" do
            cap = resource.effective_spend_cap_cents
            spent = resource.spent_in_current_period
            if cap.present? && cap.positive?
              percent = [((spent.to_f / cap) * 100).round(1), 100.0].min
              "#{percent}% of #{resource.spend_period == 'daily' ? 'daily' : 'monthly'} allowance"
            else
              "No allowance limit"
            end
          end
          row :spend_period
        end

        panel "Usage" do
          render partial: "kubik_ai/admin/usage_dashboard", locals: { configuration: resource }
        end
      end
    end
  end

  form do |f|
    tabs do
      tab "General" do
        f.inputs do
          f.input :enabled
          f.input :vision_model, hint: "RubyLLM model id (e.g. gemini-2.0-flash, gpt-4o)"
          f.input :site_context, as: :text, input_html: { rows: 6 },
                                hint: "Overall site context for every AI run (brand, audience, tone)."
          f.input :credential_source,
                  as: :select,
                  collection: Kubik::AiConfiguration::CREDENTIAL_SOURCES
        end
      end

      tab "AI instructions" do
        f.inputs "Feature-specific guidance (like ChatGPT custom instructions)" do
          f.input :context_seo, as: :text, input_html: { rows: 6 },
                                 hint: "Default SEO instructions; Pages and News can override under their index → Settings."
          f.input :context_social, as: :text, input_html: { rows: 6 },
                                   hint: "Default social instructions; content types can override in their Settings."
        end
      end

      tab "Features" do
        f.inputs do
          f.input :meta_tag_suggestions, as: :boolean,
                                         hint: "Per content-type overrides: Pages / News → Settings."
          f.input :seo_keyword_emphasis, as: :boolean
        end
        if defined?(KubikSettings::ResourceResolver) && KubikSettings::ResourceResolver.registered?(:media)
          para link_to("Media upload AI features: Media → Settings",
                       KubikSettings::ResourceResolver.edit_path(:media))
        end
      end

      tab "Providers" do
        f.inputs "API keys (stored encrypted when credential source is database)" do
          creds = f.object.provider_credentials || {}
          f.fields_for :provider_credentials, OpenStruct.new(creds) do |cf|
            cf.input :openai_api_key, as: :password, input_html: { autocomplete: "off" }
            cf.input :anthropic_api_key, as: :password, input_html: { autocomplete: "off" }
            cf.input :gemini_api_key, as: :password, input_html: { autocomplete: "off" }
          end
        end
      end

      tab "Limits" do
        f.inputs do
          f.input :spend_cap_cents,
                  hint: "Internal allowance override (cents). Leave blank to use the site default from KubikAi config / ENV."
          f.input :spend_period, as: :select, collection: Kubik::AiConfiguration::SPEND_PERIODS
        end
      end
    end
    f.actions
  end

  KubikAi.config.active_admin_blocks.each do |block|
    instance_eval(&block)
  end
end
