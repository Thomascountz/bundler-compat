# frozen_string_literal: true

require "test_helper"
require "bundler/compat/reporters/base_reporter"
require "bundler/compat/target_gem"
require "bundler/compat/result"

class TestBaseReporter < Minitest::Test
  def setup
    @results = Bundler::Compat::Result::Group.new
    @target_gem = Bundler::Compat::TargetGem.new(name: "rails", version: "7.0.0")
  end

  def test_initialization_with_valid_arguments
    reporter = Bundler::Compat::Reporters::BaseReporter.new(@results, target_gem: @target_gem)
    assert_instance_of Bundler::Compat::Reporters::BaseReporter, reporter
  end

  def test_initialization_fails_without_target_gem
    results = Bundler::Compat::Result::Group.new
    assert_raises ArgumentError, "target_gem is required" do
      Bundler::Compat::Reporters::BaseReporter.new(results, target_gem: nil)
    end
  end

  def test_print_method_raises_not_implemented_error
    reporter = Bundler::Compat::Reporters::BaseReporter.new(@results, target_gem: @target_gem)

    assert_raises NotImplementedError, "Subclasses must implement the report method" do
      reporter.print(@results)
    end
  end

  def test_preamble_contains_expected_information
    conflict = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "devise",
      direct_dependency_version: "4.8.0",
      blocking_dependency: "responders",
      blocking_dependency_version: "3.0.1",
      target_dependency: "railties",
      target_dependency_version: "6.1.0",
      target_dependency_requirement: ">= 5.2.0",
      dependency_chain: "devise -> responders -> railties"
    )
    @results.add(conflict)

    reporter = Bundler::Compat::Reporters::BaseReporter.new(@results, target_gem: @target_gem)

    preamble = reporter.send(:preamble)

    assert_includes preamble.join, "Bundle Compatibility Report"
    assert_includes preamble.join, "Target rails version: 7.0.0"
    assert_includes preamble.join, "Found 1 conflicts(s)"
    assert_includes preamble.join, "=" * 50
  end

  def test_preamble_with_no_conflicts
    reporter = Bundler::Compat::Reporters::BaseReporter.new(@results, target_gem: @target_gem)

    preamble = reporter.send(:preamble)

    assert_includes preamble.join, "Found 0 conflicts(s)"
  end

  def test_preamble_with_multiple_conflicts
    conflict1 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "devise",
      direct_dependency_version: "4.8.0",
      blocking_dependency: "responders",
      blocking_dependency_version: "3.0.1",
      target_dependency: "railties",
      target_dependency_version: "6.1.0",
      target_dependency_requirement: ">= 5.2.0",
      dependency_chain: "devise -> responders -> railties"
    )
    conflict2 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "activeadmin",
      direct_dependency_version: "2.9.0",
      blocking_dependency: "kaminari",
      blocking_dependency_version: "1.2.1",
      target_dependency: "activerecord",
      target_dependency_version: "6.1.0",
      target_dependency_requirement: "~> 6.0",
      dependency_chain: "activeadmin -> kaminari -> activerecord"
    )

    @results.add(conflict1)
    @results.add(conflict2)

    reporter = Bundler::Compat::Reporters::BaseReporter.new(@results, target_gem: @target_gem)

    preamble = reporter.send(:preamble)

    assert_includes preamble.join, "Found 2 conflicts(s)"
  end

  def test_target_gem_display_name_in_preamble
    non_rails_target = Bundler::Compat::TargetGem.new(name: "devise", version: "4.8.0")
    reporter = Bundler::Compat::Reporters::BaseReporter.new(@results, target_gem: non_rails_target)

    preamble = reporter.send(:preamble)

    assert_includes preamble.join, "Target devise version: 4.8.0"
  end
end
