# frozen_string_literal: true

require "test_helper"
require "bundler/compat/result"

class TestResult < Minitest::Test
  def setup
    @conflict = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "rails",
      direct_dependency_version: "7.0.0",
      blocking_dependency: "activerecord",
      blocking_dependency_version: "7.0.0",
      target_dependency: "pg",
      target_dependency_version: "1.4.0",
      target_dependency_requirement: "~> 1.4",
      dependency_chain: "rails (7.0.0) -> activerecord (7.0.0) -> pg (1.4.0)"
    )
  end

  def test_conflict_data_structure_creation
    # Setup done in setup method

    # Execute & Assert
    assert_equal "rails", @conflict.direct_dependency
    assert_equal "7.0.0", @conflict.direct_dependency_version
    assert_equal "activerecord", @conflict.blocking_dependency
    assert_equal "7.0.0", @conflict.blocking_dependency_version
    assert_equal "pg", @conflict.target_dependency
    assert_equal "1.4.0", @conflict.target_dependency_version
    assert_equal "~> 1.4", @conflict.target_dependency_requirement
    assert_equal "rails (7.0.0) -> activerecord (7.0.0) -> pg (1.4.0)", @conflict.dependency_chain
  end

  def test_group_initialization
    # Setup
    group = Bundler::Compat::Result::Group.new

    # Execute & Assert
    assert_equal 0, group.size
    assert_empty group.conflicts
    assert_respond_to group, :each
  end

  def test_group_adding_conflicts
    # Setup
    group = Bundler::Compat::Result::Group.new

    # Execute
    group.add(@conflict)

    # Assert
    assert_equal 1, group.size
    assert_equal [@conflict], group.conflicts
  end

  def test_group_enumerable_behavior
    # Setup
    group = Bundler::Compat::Result::Group.new
    conflict2 = Bundler::Compat::Result::Conflict.new(
      direct_dependency: "devise",
      direct_dependency_version: "4.8.0",
      blocking_dependency: "responders",
      blocking_dependency_version: "3.0.1",
      target_dependency: "railties",
      target_dependency_version: "6.1.0",
      target_dependency_requirement: ">= 5.2.0",
      dependency_chain: "devise -> responders -> railties"
    )

    group.add(@conflict)
    group.add(conflict2)

    # Execute & Assert
    results = []
    group.each { |item| results << item }
    assert_equal 2, results.size
    assert_includes results, @conflict
    assert_includes results, conflict2
  end

  def test_group_filters_by_type
    # Setup
    group = Bundler::Compat::Result::Group.new
    group.add(@conflict)

    # Execute
    conflicts = group.filter_by_type(Bundler::Compat::Result::Conflict)

    # Assert
    assert_equal [@conflict], conflicts
  end

  def test_group_conflicts_method_filters_conflicts
    # Setup
    group = Bundler::Compat::Result::Group.new
    group.add(@conflict)

    # Execute
    conflicts = group.conflicts

    # Assert
    assert_equal [@conflict], conflicts
    assert_instance_of Array, conflicts
  end

  def test_group_prevents_duplicate_conflicts
    # Setup
    group = Bundler::Compat::Result::Group.new

    # Execute
    group.add(@conflict)
    group.add(@conflict) # Adding same conflict twice

    # Assert - Set behavior should prevent duplicates
    assert_equal 1, group.size
  end

  def test_empty_group_returns_empty_conflicts
    # Setup
    group = Bundler::Compat::Result::Group.new

    # Execute & Assert
    assert_empty group.conflicts
    assert_equal 0, group.size
  end
end
