# frozen_string_literal: true

require "test_helper"

class KubikAiRestartAnalysisTest < Minitest::Test
  def test_normalize_operation_defaults_to_analyze
    upload = Struct.new(:additional_info).new({ "kubik_ai" => { "operation" => "bogus" } })
    op = KubikAi::Media::RestartAnalysis.normalize_operation(nil, upload)
    assert_equal "analyze", op
  end

  def test_normalize_operation_preserves_reinterpret
    upload = Struct.new(:additional_info).new({ "kubik_ai" => { "operation" => "reinterpret" } })
    op = KubikAi::Media::RestartAnalysis.normalize_operation(nil, upload)
    assert_equal "reinterpret", op
  end
end
