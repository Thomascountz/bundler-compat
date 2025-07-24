# frozen_string_literal: true

require "test_helper"
require "bundler/compat/conflict_finder"

class TestConflictFinder < Minitest::Test
  def test_finds_no_conflicts_when_all_dependencies_are_compatible
    # Simple lockfile with Rails 7.0 and compatible gems
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          actionpack (7.0.0)
          activesupport (7.0.0)
          rails (7.0.0)
            actionpack (= 7.0.0)
            activesupport (= 7.0.0)

      DEPENDENCIES
        rails

      BUNDLED WITH
         2.4.0
    LOCKFILE

    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_version: "7.0.0"
    )

    results = finder.search

    assert_equal 0, results.conflicts.size
  end

  def test_finds_conflict_when_gem_requires_older_rails_component
    # Lockfile where a gem depends on an older actionpack version
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          actionpack (6.1.0)
          old_gem (1.0.0)
            actionpack (~> 6.0)

      DEPENDENCIES
        old_gem

      BUNDLED WITH
         2.4.0
    LOCKFILE

    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_version: "7.0.0"
    )

    results = finder.search
    conflicts = results.conflicts

    assert_equal 1, conflicts.size

    conflict = conflicts.first
    assert_equal "old_gem", conflict.direct_dependency
    assert_equal "old_gem", conflict.blocking_dependency
    assert_equal "actionpack", conflict.target_dependency
    assert_equal "~> 6.0", conflict.target_dependency_requirement
  end

  def test_finds_multiple_conflicts_in_dependency_chain
    # Lockfile with a gem that depends on another gem that requires old Rails
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          actionpack (6.1.0)
          activesupport (6.1.0)
          intermediate_gem (2.0.0)
            problem_gem (~> 1.0)
          problem_gem (1.5.0)
            actionpack (~> 6.0)
            activesupport (< 7.0)
          top_level_gem (1.0.0)
            intermediate_gem (~> 2.0)

      DEPENDENCIES
        top_level_gem

      BUNDLED WITH
         2.4.0
    LOCKFILE

    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_version: "7.0.0"
    )

    results = finder.search
    conflicts = results.conflicts

    # Should find conflicts for both actionpack and activesupport
    assert_equal 2, conflicts.size

    # All conflicts should trace back to top_level_gem as the direct dependency
    conflicts.each do |conflict|
      assert_equal "top_level_gem", conflict.direct_dependency
    end

    # Should have different target dependencies
    target_deps = conflicts.map(&:target_dependency).sort
    assert_equal ["actionpack", "activesupport"], target_deps
  end

  def test_stops_traversal_at_rails_components
    # Lockfile that includes Rails gems directly - shouldn't traverse into them
    lockfile_content = <<~LOCKFILE
      GEM
        remote: https://rubygems.org/
        specs:
          actionpack (7.0.0)
            some_internal_dep (1.0.0)
          rails (7.0.0)
            actionpack (= 7.0.0)

      DEPENDENCIES
        rails

      BUNDLED WITH
         2.4.0
    LOCKFILE

    finder = Bundler::Compat::ConflictFinder.new(
      lockfile_contents: lockfile_content,
      target_version: "7.0.0"
    )

    results = finder.search

    # Should not find any conflicts since it stops at Rails components
    assert_equal 0, results.conflicts.size
  end
end
