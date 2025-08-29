# frozen_string_literal: true

require "test_helper"
require "bundler/compat/target_gem"
require "bundler/compat/conflict_finder"
require "bundler/compat/reporters/json_reporter"
require "bundler/compat/reporters/text_reporter"

class TestIntegrationFixtures < Minitest::Test
  FIXTURES_DIR = File.join(__dir__, "fixtures")

  def test_rails_8_upgrade_from_fixture_a
    # Setup - Using the real-world Gemfile.lock from rubygems.org
    lockfile_content = File.read(File.join(FIXTURES_DIR, "A_Gemfile.lock"))
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "8.1.0")

    # Execute
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )
    results = finder.search

    # Assert - This fixture already has Rails 8.0.2, so upgrading to 8.1.0 should have minimal conflicts
    conflicts = results.conflicts

    # Test that the finder successfully processes the complex lockfile
    assert_respond_to results, :conflicts
    assert_instance_of Array, conflicts

    # Test JSON reporter with real fixture
    json_reporter = Bundler::Compat::Reporters::JsonReporter.new(results, target_gem: target_gem)
    json_output = StringIO.new
    json_reporter.print(output: json_output)

    json_data = JSON.parse(json_output.string)
    assert_equal "rails", json_data["target_gem"]
    assert_equal "8.1.0", json_data["target_version"]
    assert_kind_of Integer, json_data["conflicts_count"]
    assert_kind_of Array, json_data["conflicts"]
  end

  def test_rails_7_downgrade_from_fixture_a
    # Setup - Test downgrading from Rails 8 to Rails 7 (likely to have conflicts)
    lockfile_content = File.read(File.join(FIXTURES_DIR, "A_Gemfile.lock"))
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")

    # Execute
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )
    results = finder.search

    # Assert - Downgrading should likely produce conflicts
    conflicts = results.conflicts

    # Test that each conflict has required fields
    conflicts.each do |conflict|
      assert_respond_to conflict, :direct_dependency
      assert_respond_to conflict, :blocking_dependency
      assert_respond_to conflict, :target_dependency
      assert_respond_to conflict, :target_dependency_requirement
      refute_nil conflict.direct_dependency
      refute_nil conflict.blocking_dependency
      refute_nil conflict.target_dependency
    end
  end

  def test_non_rails_gem_compatibility_with_fixture_a
    # Setup - Test compatibility with a different gem (not Rails)
    lockfile_content = File.read(File.join(FIXTURES_DIR, "A_Gemfile.lock"))
    target_gem = Bundler::Compat::TargetGem.new(name: "nokogiri", version: "1.20.0")

    # Execute
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )
    results = finder.search

    # Assert
    assert_respond_to results, :conflicts
    refute target_gem.components? # nokogiri should not have components
    assert_equal "nokogiri", target_gem.display_name
  end

  def test_text_reporter_handles_complex_fixture
    # Setup
    lockfile_content = File.read(File.join(FIXTURES_DIR, "A_Gemfile.lock"))
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")

    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )
    results = finder.search

    # Execute
    text_reporter = Bundler::Compat::Reporters::TextReporter.new(results, target_gem: target_gem)
    output = StringIO.new
    text_reporter.print(output: output)

    # Assert - Text output should be well-formatted
    text = output.string
    assert_includes text, "Bundle Compatibility Report"
    assert_includes text, "Target rails version: 7.0.0"
    assert_match(/Found \d+ conflicts\(s\)/, text)

    # Should not crash with complex real-world data
    refute_empty text
  end

  def test_multiple_fixtures_processing
    # Setup - Test that different fixtures can be processed
    fixture_files = Dir.glob(File.join(FIXTURES_DIR, "*_Gemfile.lock"))
    target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")

    # Execute & Assert
    fixture_files.each do |fixture_file|
      lockfile_content = File.read(fixture_file)

      finder = Bundler::Compat::ConflictFinder.new(
        lockfile_contents: lockfile_content,
        target_gem: target_gem
      )

      # Should not raise errors when processing any fixture
      results = finder.search
      assert_respond_to results, :conflicts
    end
  end

  def test_fixture_data_integrity
    # Setup & Execute - Verify all fixtures are readable and valid
    fixture_files = Dir.glob(File.join(FIXTURES_DIR, "*_Gemfile.lock"))

    # Assert
    assert fixture_files.size > 0, "Should have fixture files to test with"

    fixture_files.each do |fixture_file|
      content = File.read(fixture_file)

      # Basic format validation
      assert_includes content, "GEM", "#{fixture_file} should contain GEM section"
      assert_includes content, "DEPENDENCIES", "#{fixture_file} should contain DEPENDENCIES section"
      refute_empty content.strip, "#{fixture_file} should not be empty"
    end
  end

  def test_rails_component_targeting_with_fixture
    # Setup - Test targeting a specific Rails component
    lockfile_content = File.read(File.join(FIXTURES_DIR, "A_Gemfile.lock"))
    target_gem = Bundler::Compat::TargetGem.new(name: "actionpack", version: "7.0.0")

    # Execute
    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_gem: target_gem
    )
    results = finder.search

    # Assert - Should work for individual Rails components too
    assert_respond_to results, :conflicts
    refute target_gem.components? # Individual component should not have sub-components
    assert_equal "actionpack", target_gem.display_name
  end

  private

  def require_fixture(filename)
    File.read(File.join(FIXTURES_DIR, filename))
  end
end
