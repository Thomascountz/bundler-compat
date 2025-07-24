# frozen_string_literal: true

require "test_helper"
require "bundler/compat/reporters/text_reporter"
require "bundler/compat/result"
require "stringio"

class TestTextReporter < Minitest::Test
  def test_reports_no_conflicts
    results = Bundler::Compat::Result::Group.new
    reporter = Bundler::Compat::Reporters::TextReporter.new(results)

    output = StringIO.new
    reporter.print(output: output)

    assert_includes output.string, "Bundle Compatibility Report"
    assert_includes output.string, "Found 0 conflicts(s)"
  end

  def test_reports_single_conflict
    conflict = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "rails",
      direct_dependency_version: "6.1.0",
      blocking_dependency: "activerecord",
      blocking_dependency_version: "6.1.0",
      target_dependency: "sqlite3",
      target_dependency_version: "1.4.0",
      target_dependency_requirement: "~> 1.4",
      dependency_chain: ["rails", "activerecord", "sqlite3"]
    )

    results = Bundler::Compat::Result::Group.new
    results.add(conflict)

    reporter = Bundler::Compat::Reporters::TextReporter.new(results)

    output = StringIO.new
    reporter.print(output: output)

    text = output.string
    assert_includes text, "Found 1 conflicts(s)"
    assert_includes text, "rails:"
    assert_includes text, "activerecord (6.1.0)"
    assert_includes text, "requires sqlite3 ~> 1.4"
    assert_includes text, "dependency_chain: [\"rails\", \"activerecord\", \"sqlite3\"]"
  end

  def test_groups_conflicts_by_direct_dependency
    conflict1 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "rails",
      direct_dependency_version: "7.0.0",
      blocking_dependency: "activerecord",
      blocking_dependency_version: "7.0.0",
      target_dependency: "pg",
      target_dependency_version: "1.2.0",
      target_dependency_requirement: ">= 1.1",
      dependency_chain: []
    )

    conflict2 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "rails",
      direct_dependency_version: "7.0.0",
      blocking_dependency: "actionview",
      blocking_dependency_version: "7.0.0",
      target_dependency: "nokogiri",
      target_dependency_version: "1.13.0",
      target_dependency_requirement: "~> 1.6",
      dependency_chain: []
    )

    results = Bundler::Compat::Result::Group.new
    results.add(conflict1)
    results.add(conflict2)

    reporter = Bundler::Compat::Reporters::TextReporter.new(results)

    output = StringIO.new
    reporter.print(output: output)

    text = output.string
    assert_includes text, "Found 2 conflicts(s)"
    # Should only show "rails:" once as a header
    assert_equal 1, text.scan(/^rails:$/).size
    assert_includes text, "activerecord (7.0.0)"
    assert_includes text, "actionview (7.0.0)"
  end
end
