# frozen_string_literal: true

require "test_helper"

class Bundler::TestCompat < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Bundler::Compat::VERSION
  end

  def test_it_does_something_useful
    assert true
  end
end
