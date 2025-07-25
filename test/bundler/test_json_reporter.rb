# frozen_string_literal: true

require "test_helper"
require "bundler/compat/reporters/json_reporter"
require "bundler/compat/result"
require "json"
require "stringio"

class TestJsonReporter < Minitest::Test
  def test_empty_results_json_output
    results = Bundler::Compat::Result::Group.new
    reporter = Bundler::Compat::Reporters::JsonReporter.new(results, target_version: "7.0.0")

    output = StringIO.new
    reporter.print(output: output)

    json_data = JSON.parse(output.string)

    assert_equal "7.0.0", json_data["target_rails_version"]
    assert_equal 0, json_data["conflicts_count"]
    assert_equal [], json_data["conflicts"]
  end

  def test_single_conflict_json_output
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

    reporter = Bundler::Compat::Reporters::JsonReporter.new(results, target_version: "7.0.0")

    output = StringIO.new
    reporter.print(output: output)

    json_data = JSON.parse(output.string)

    assert_equal "7.0.0", json_data["target_rails_version"]
    assert_equal 1, json_data["conflicts_count"]
    assert_equal 1, json_data["conflicts"].size

    conflict_group = json_data["conflicts"].first
    assert_equal "rails", conflict_group["direct_dependency"]
    assert_equal "6.1.0", conflict_group["direct_dependency_version"]
    assert_equal 1, conflict_group["blocking_dependencies"].size

    blocking_dep = conflict_group["blocking_dependencies"].first
    assert_equal "activerecord", blocking_dep["blocking_dependency"]
    assert_equal "6.1.0", blocking_dep["blocking_dependency_version"]
    assert_equal "sqlite3", blocking_dep["target_dependency"]
    assert_equal "1.4.0", blocking_dep["target_dependency_version"]
    assert_equal "~> 1.4", blocking_dep["target_dependency_requirement"]
    assert_equal ["rails", "activerecord", "sqlite3"], blocking_dep["dependency_chain"]
  end

  def test_multiple_conflicts_json_output
    conflict1 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "rails",
      direct_dependency_version: "6.1.0",
      blocking_dependency: "activerecord",
      blocking_dependency_version: "6.1.0",
      target_dependency: "sqlite3",
      target_dependency_version: "1.4.0",
      target_dependency_requirement: "~> 1.4",
      dependency_chain: ["rails", "activerecord", "sqlite3"]
    )

    conflict2 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "devise",
      direct_dependency_version: "4.8.0",
      blocking_dependency: "responders",
      blocking_dependency_version: "3.0.1",
      target_dependency: "railties",
      target_dependency_version: "6.1.0",
      target_dependency_requirement: ">= 5.2.0",
      dependency_chain: ["devise", "responders", "railties"]
    )

    results = Bundler::Compat::Result::Group.new
    results.add(conflict1)
    results.add(conflict2)

    reporter = Bundler::Compat::Reporters::JsonReporter.new(results, target_version: "7.0.0")

    output = StringIO.new
    reporter.print(output: output)

    json_data = JSON.parse(output.string)

    assert_equal "7.0.0", json_data["target_rails_version"]
    assert_equal 2, json_data["conflicts_count"]
    assert_equal 2, json_data["conflicts"].size
  end
end
