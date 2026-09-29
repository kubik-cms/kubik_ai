# frozen_string_literal: true

# Metatag support is loaded explicitly so Solid Queue / job workers always have
# constants available (lib/ is not on the engine Zeitwerk autoload paths).
module KubikAi
  module Metatag
  end
end

require "kubik_ai/metatag/store"
require "kubik_ai/metatag/suggestion_store"
require "kubik_ai/metatag/broadcaster"
require "kubik_ai/metatag/sync_stream"
require "kubik_ai/metatag/runtime_state"
require "kubik_ai/metatag/paths"
require "kubik_ai/metatag/panel_dom"
require "kubik_ai/metatag/panel_sync_attributes"
require "kubik_ai/metatag/form_sync_fields"
require "kubik_ai/metatag/pending_applier"
require "kubik_ai/metatag/content_fields"
require "kubik_ai/metatag/focus"
require "kubik_ai/metatag/stale_recovery"
require "kubik_ai/metatag/suggestor"
