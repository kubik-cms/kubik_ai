# frozen_string_literal: true

require "test_helper"

class KubikAiSuggestionsMediaUploadSetTest < ActiveSupport::TestCase
  include ActionView::TestCase::Behavior

  test "media upload set renders field markup for pending suggestions" do
    upload = Struct.new(:id).new(42)
    set = KubikAi::Suggestions::MediaUploadSet.for(upload)
    pending = {
      "alt_text" => "Sunset",
      "tags" => %w[beach],
      "previous" => { "alt_text" => "", "tags" => [] }
    }

    html = set.render(view, upload: upload, pending: pending, previous: pending["previous"])

    assert_includes html, "kubik-panel-field"
    assert_includes html, 'name="kubik_ai_pending[alt_text]"'
    assert_includes html, "Sunset"
    assert_not_includes html, "index_table"
  end
end
