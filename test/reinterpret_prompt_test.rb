# frozen_string_literal: true

require "test_helper"

class KubikAiReinterpretPromptTest < ActiveSupport::TestCase
  test "store! persists prompt for the job and last_additional_prompt for the form" do
    upload = stub_upload
    KubikAi::Media::ReinterpretPrompt.store!(upload, "  mention the pier  ")

    assert_equal "mention the pier", upload.additional_info.dig("kubik_ai", "current_reinterpret_prompt")
    assert_equal "mention the pier", upload.additional_info.dig("kubik_ai", "last_additional_prompt")
  end

  test "append_to_instructions adds editor section" do
    result = KubikAi::Media::ReinterpretPrompt.append_to_instructions("site context", "use UK spelling")
    assert_includes result, "Additional instructions from editor"
    assert_includes result, "highest priority"
    assert_includes result, "use UK spelling"
  end

  test "append_to_instructions can include current media state" do
    result = KubikAi::Media::ReinterpretPrompt.append_to_instructions(
      "site context",
      "mention the pier",
      media_state: "Alt text currently saved on this media item: Boat at sea"
    )
    assert_includes result, "Current media record"
    assert_includes result, "Boat at sea"
    assert_includes result, "mention the pier"
  end

  private

  def stub_upload
    info = { "kubik_ai" => {} }
    upload = Object.new
    upload.define_singleton_method(:additional_info) { info }
    upload.define_singleton_method(:update!) do |attrs|
      self.additional_info.replace(attrs[:additional_info]) if attrs.key?(:additional_info)
      true
    end
    upload
  end
end
