# frozen_string_literal: true

require "test_helper"
require "bundler/compat/target_gem"

class TestTargetGem < Minitest::Test
  def test_non_rails_gem_has_no_components
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: "devise", version: "4.8.0")

    # Execute & Assert
    refute target_gem.components?
    assert_equal Set["devise"], target_gem.target_gems
    assert_equal "devise", target_gem.display_name
  end

  def test_rails_gem_has_components
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")

    # Execute & Assert
    assert target_gem.components?
    expected_components = %w[
      actioncable actionmailbox actionmailer actionpack actiontext actionview
      activejob activemodel activerecord activestorage activesupport railties rails
    ].to_set
    assert_equal expected_components, target_gem.target_gems
    assert_equal "rails (13 components)", target_gem.display_name
  end

  def test_rails_gem_case_insensitive
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: "RAILS", version: "6.1.0")

    # Execute & Assert
    assert target_gem.components?
    assert_includes target_gem.target_gems, "actionpack"
    assert_includes target_gem.target_gems, "rails"
  end

  def test_version_parsing
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.4.1")

    # Execute & Assert
    assert_equal Gem::Version.new("7.0.4.1"), target_gem.version
  end

  def test_name_and_version_accessors
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: "activerecord", version: "6.1.4")

    # Execute & Assert
    assert_equal "activerecord", target_gem.name
    assert_equal Gem::Version.new("6.1.4"), target_gem.version
  end

  def test_string_conversion_of_name
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: :rails, version: "7.0.0")

    # Execute & Assert
    assert_equal "rails", target_gem.name
    assert target_gem.components?
  end
end
