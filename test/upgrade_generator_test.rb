# frozen_string_literal: true

require "test_helper"
require "generators/kubik/ai/upgrade_generator"

class UpgradeGeneratorTest < Minitest::Test
  def test_generator_is_defined
    assert Kubik::Generators::Ai::UpgradeGenerator
  end
end
