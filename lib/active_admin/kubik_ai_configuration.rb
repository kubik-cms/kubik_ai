# frozen_string_literal: true

# Loaded via ActiveAdmin load_paths (see KubikAi::Engine) so controllers reload in development.
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

      tab "Features" do
        attributes_table_for resource do
          resource.feature_flags.each do |key, value|
            row key.to_s.humanize do
              value
            end
          end
        end
      end

      tab "Limits & usage" do
        attributes_table_for resource do
          row :spend_cap_cents
          row :spend_period
          row "Spent this period" do
            Kubik::AiUsageEvent.spent_in_period(resource.spend_period)
          end
        end

        panel "Recent usage" do
          table_for Kubik::AiUsageEvent.order(created_at: :desc).limit(25) do
            column :created_at
            column :operation
            column :model
            column :estimated_cost_cents
            column :status
          end
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
          f.input :site_context, as: :text, input_html: { rows: 8 },
                                hint: "Describe the site, audience, and how images should be interpreted."
          f.input :credential_source,
                  as: :select,
                  collection: Kubik::AiConfiguration::CREDENTIAL_SOURCES
        end
      end

      tab "Features" do
        f.inputs do
          f.input :auto_analyze_on_upload, as: :boolean
          f.input :auto_apply_alt_text, as: :boolean
          f.input :auto_apply_tags, as: :boolean
          f.input :meta_tag_suggestions, as: :boolean
          f.input :seo_keyword_emphasis, as: :boolean
          f.input :prefer_no_faces, as: :boolean
          f.input :tag_vocabulary_hints, as: :string
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
          f.input :spend_cap_cents, hint: "Leave blank for no cap"
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
