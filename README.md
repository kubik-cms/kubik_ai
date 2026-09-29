# Kubik AI

AI integrations for Kubik CMS: site context compilation, RubyLLM gateway, usage limits, and media image analysis.

## Installation

Add to your Gemfile:

```ruby
gem "kubik_ai", github: "kubik-cms/kubik_ai"
```

For local development, use `path: "vendor/kubik_ai"` or a devcontainer mount.

```bash
bundle install
bin/rails kubik:ai:install   # or: bin/rails generate kubik:ai:install
bin/rails db:migrate
```

### Upgrading

New database changes ship as generator templates in the gem (not hand-written in host apps). After updating `kubik_ai`:

```bash
bin/rails kubik:ai:upgrade   # or: bin/rails generate kubik:ai:upgrade
bin/rails db:migrate
```

`kubik:ai:upgrade` is idempotent: it skips migrations when the schema is already up to date.

Fresh installs only need `kubik:ai:install` (the configurations table includes `context_instructions`).

### Active Record encryption

Database-stored API keys use `encrypts :provider_credentials`. In production, run `bin/rails db:encryption:init` and add the keys to credentials or set:

- `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY`
- `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY`
- `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT`

The booking app sets development/test keys in `config/application.rb` so local admin works without extra setup.

### API keys

- **env** (default): set `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or `GEMINI_API_KEY`.
- **database**: set credential source in Admin → AI → Providers.

## AI instructions (Admin → Website → AI)

- **Site context** — included on every AI run (brand, audience, tone).
- **Media / SEO / Social** — feature-specific instructions (like ChatGPT custom instructions), compiled only when that feature runs (image analysis, meta SEO panels, social panels).
- Per-run **optional instructions** on meta tag retries are still supported in the editor UI.

Register additional context from an initializer:

```ruby
KubikAi.configure do |config|
  config.register_context_provider :my_seo, MySeoContextProvider
end
```

Providers inherit `KubikAi::Context::Providers::Base` and implement `#to_prompt`.

## Media library

When `kubik_media_library` is present, images enqueue analysis when they reach the `ready` state. On media edit, use the robot icon in the image details fieldset legend to open the AI assistant offcanvas (suggestions, apply/discard, reinterpret).

## Meta tags (pages, trips, news, etc.)

On edit screens for metataggable resources, the **robot icon in the Meta tab header** opens the same style of offcanvas: queue AI suggestions (Turbo broadcasts while processing), review fields, then apply or discard. Applying updates the Meta tab fields on the main form via `kubik-ai-metatag-sync`.

Focus-scoped panels (`seo`, `meta_description`, `social`, etc.) use separate runtime state and DOM ids per focus. Stale `queued`/`processing` UI is cleared automatically after `KUBIK_AI_METATAG_STALE_SECONDS` (default 10).

Host apps that rely on Turbo broadcasts only (no HTTP panel poller) should set:

```ruby
KubikAi.configure do |config|
  config.metatag_broadcast_only = true
end
```

**Previous suggestions** (`additional_info.kubik_ai.history`) lists alt/tags (and optional editor prompt) for suggestions you **applied** to the media record. Reinterpret-only runs and discarded suggestions are not listed. Optional text in the blue CTA is sent to the model on reinterpret and stored on the history row when you apply.

## Suggestion sets (UI API)

Register a suggestion field set for a domain object, then render editable AI proposals with Kubik form controls:

```ruby
# config/initializers/kubik_ai.rb
KubikAi.configure do |config|
  config.suggestion_sets[:my_feature] = MyFeature::AiSuggestionSet
end
```

A set is a `KubikAi::Suggestions::Set` of `KubikAi::Suggestions::Field` entries (`:text`, `:textarea`, `:tags`). Render in a view:

```erb
<% set = KubikAi.config.suggestion_sets[:media_upload].for(upload) %>
<%= set.render(self, upload: upload, pending: pending, previous: previous) %>
```

See `KubikAi::Suggestions::MediaUploadSet` and `app/views/kubik_ai/suggestions/_field.html.erb` for the media upload reference implementation.

## Offcanvas panel UI

The media AI offcanvas uses shared **Kubik interface panel** primitives from `kubik_interface_elements` (`kubik_panel_shell`, `kubik_panel_cta`, `kubik_panel_widget`, `kubik_panel_fieldset`, `kubik_panel_field_sub_label`, `kubik_panel_audit_table`). Domain logic and copy stay in `kubik_ai`; layout and styling live in the gem (`_panel_chrome.scss`).
