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

  def test_ai_normalize_keeps_multi_word_tags
    tags = KubikAi::Media::TagList.normalize(["loch ness", "highland"], from_llm: true, max_tags: 5)
    assert_equal %w[loch ness highland], tags
  end

  def test_ai_normalize_drops_noise_tags
    tags = KubikAi::Media::TagList.normalize(["loch ness", "no", "faces", "sunset"], from_llm: true, max_tags: 5)
    assert_equal %w[loch ness sunset], tags
  end

  def test_ai_normalize_limits_tag_count
    tags = KubikAi::Media::TagList.normalize(
      %w[one two three four five six],
      from_llm: true,
      max_tags: 3
    )
    assert_equal %w[one two three], tags
  end
end
