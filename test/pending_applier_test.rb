# frozen_string_literal: true

require "test_helper"

class KubikAiPendingApplierTest < ActiveSupport::TestCase
  test "apply merges alt text and tag overrides from form params" do
    upload = stub_upload(
      pending: {
        "alt_text" => "AI alt",
        "tags" => %w[hero beach],
        "previous" => { "alt_text" => "old", "tags" => [] }
      }
    )

    KubikAi::Media::PendingApplier.apply!(
      upload,
      overrides: { alt_text: "Edited alt", media_tag_list: "sunset" }
    )

    assert_equal "Edited alt", upload.additional_info["alt_text"]
    assert_equal %w[sunset], upload.assigned_tags
    assert_nil upload.additional_info.dig("kubik_ai", "pending")
  end

  private

  def stub_upload(pending:)
    info = { "kubik_ai" => { "pending" => pending, "history" => [] } }
    tags = []

    upload = Object.new
    upload.define_singleton_method(:additional_info) { info }
    upload.define_singleton_method(:additional_info=) { |value| info.replace(value) }
    upload.define_singleton_method(:assigned_tags) { tags }
    upload.define_singleton_method(:set_tag_list_on) do |_context, list|
      tags.replace(list)
    end
    upload.define_singleton_method(:save!) { true }
    upload.define_singleton_method(:update!) do |attrs|
      self.additional_info = attrs[:additional_info] if attrs.key?(:additional_info)
      true
    end
    upload
  end
end
