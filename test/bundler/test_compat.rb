# frozen_string_literal: true

require "test_helper"
require "bundler/compat"
require "bundler/compat/target_gem"
require "bundler/compat/conflict_finder"
require "bundler/compat/reporters/json_reporter"
require "bundler/compat/reporters/text_reporter"
require "stringio"

class Bundler::TestCompat < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Bundler::Compat::VERSION
  end

  def test_complete_workflow_with_no_conflicts
    # Setup
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          rails (7.0.0)
            actionpack (= 7.0.0)
            activesupport (= 7.0.0)
          actionpack (7.0.0)
          activesupport (7.0.0)

      DEPENDENCIES
        rails

      BUNDLED WITH
         2.4.0
    LOCKFILE

    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )

    # Execute
    results = finder.search

    # Assert
    assert_equal 0, results.conflicts.size

    # Test JSON reporter integration
    json_output = StringIO.new
    json_reporter = Bundler::Compat::Reporters::JsonReporter.new(results, target_gem: target_gem)
    json_reporter.print(output: json_output)

    json_data = JSON.parse(json_output.string)
    assert_equal "rails", json_data["target_gem"]
    assert_equal "7.0.0", json_data["target_version"]
    assert_equal 0, json_data["conflicts_count"]

    # Test text reporter integration
    text_output = StringIO.new
    text_reporter = Bundler::Compat::Reporters::TextReporter.new(results, target_gem: target_gem)
    text_reporter.print(output: text_output)

    assert_includes text_output.string, "Target rails version: 7.0.0"
    assert_includes text_output.string, "Found 0 conflicts(s)"
  end

  def test_complete_workflow_with_conflicts
    # Setup
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          old_gem (1.0.0)
            actionpack (~> 6.0)
          actionpack (6.1.0)

      DEPENDENCIES
        old_gem

      BUNDLED WITH
         2.4.0
    LOCKFILE

    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )

    # Execute
    results = finder.search

    # Assert
    assert_equal 1, results.conflicts.size

    conflict = results.conflicts.first
    assert_equal "old_gem", conflict.direct_dependency
    assert_equal "old_gem", conflict.blocking_dependency
    assert_equal "actionpack", conflict.target_dependency
    assert_equal "~> 6.0", conflict.target_dependency_requirement

    # Test that reporters handle conflicts correctly
    json_output = StringIO.new
    json_reporter = Bundler::Compat::Reporters::JsonReporter.new(results, target_gem: target_gem)
    json_reporter.print(output: json_output)

    json_data = JSON.parse(json_output.string)
    assert_equal 1, json_data["conflicts_count"]
    assert_equal 1, json_data["conflicts"].size
  end

  def test_rails_components_integration
    # Setup
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "8.0.0")

    # Execute & Assert
    assert target_gem.components?
    assert_includes target_gem.target_gems, "actionpack"
    assert_includes target_gem.target_gems, "activerecord"
    assert_includes target_gem.target_gems, "rails"
    assert_equal "rails (13 components)", target_gem.display_name
  end

  def test_empty_lockfile_handling
    # Setup - Test with minimal valid lockfile
    minimal_lockfile = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:

      DEPENDENCIES

      BUNDLED WITH
         2.4.0
    LOCKFILE

    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")

    # Execute
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: minimal_lockfile,
      target_gem: target_gem
    )
    results = finder.search

    # Assert - should handle empty lockfile gracefully
    assert_equal 0, results.conflicts.size
  end
end
