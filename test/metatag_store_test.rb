# frozen_string_literal: true

require "test_helper"

class KubikAiMetatagStoreTest < ActiveSupport::TestCase
  test "disk store persists pending payload for metatagable records" do
    page = Page.create!(title: "Store test", slug: "metatag-store-test-#{SecureRandom.hex(4)}", published_at: nil)

    KubikAi::Metatag::SuggestionStore.store!(page, { "title_tag" => "Suggested" })
    assert_equal "Suggested", KubikAi::Metatag::SuggestionStore.fetch(page)["title_tag"]

    KubikAi::Metatag::SuggestionStore.clear!(page)
    assert_nil KubikAi::Metatag::SuggestionStore.fetch(page)
  end
end
