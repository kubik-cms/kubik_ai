# frozen_string_literal: true

require "test_helper"

class KubikAiMediaTagListTest < ActiveSupport::TestCase
  test "normalize splits comma-separated string into multiple tags" do
    tags = KubikAi::Media::TagList.normalize("hero, brochure, 2024")
    assert_equal %w[hero brochure 2024], tags
  end

  test "normalize flattens array entries that contain commas" do
    tags = KubikAi::Media::TagList.normalize(["hero, sky", "boat"])
    assert_equal %w[hero sky boat], tags
  end
end
