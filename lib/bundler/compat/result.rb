require "set"
require "forwardable"

module Bundler
  module Compat
    class Result
      Conflict = Data.define(
        :direct_dependency, :direct_dependency_version,
        :blocking_dependency, :blocking_dependency_version,
        :target_dependency, :target_dependency_version, :target_dependency_requirement,
        :dependency_chain
      )

      class Group
        include Enumerable
        extend Forwardable

        def initialize
          @items = Set.new
        end

        def_delegators :@items, :add, :size

        def each(&block)
          @items.each(&block)
        end

        def conflicts
          filter_by_type(Result::Conflict)
        end

        def filter_by_type(type)
          @items.select { |item| item.is_a?(type) }
        end
      end
    end
  end
end
