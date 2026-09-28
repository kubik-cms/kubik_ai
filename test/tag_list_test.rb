# frozen_string_literal: true

require "test_helper"

class TagListTest < Minitest::Test
  def test_splits_comma_separated_string
    assert_equal %w[children classroom], KubikAi::Media::TagList.normalize("children, classroom")
  end

  def test_splits_single_array_element_with_commas
    assert_equal %w[children classroom no_faces],
                 KubikAi::Media::TagList.normalize(["children, classroom, no_faces"])
  end

  def test_parses_json_array_string
    assert_equal %w[hero brochure], KubikAi::Media::TagList.normalize('["hero", "brochure"]')
  end

  def test_splits_space_separated_string
    assert_equal %w[scotland castle seascape landscape],
                 KubikAi::Media::TagList.normalize("scotland castle seascape landscape")
  end
end
