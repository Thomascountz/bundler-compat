require "bundler"
require "bundler/compat/result"

module Bundler
  module Compat
    class ConflictFinder
      MAX_DEPTH = 10

      RAILS_COMPONENTS = %w[
        actioncable actionmailbox actionmailer actionpack actiontext actionview
        activejob activemodel activerecord activestorage activesupport railties rails
      ].to_set

      attr_reader :lockfile, :target_version

      def initialize(lockfile_contents: File.read(Bundler.default_lockfile), target_version: "8.1.0")
        @target_version = Gem::Version.new(target_version)
        @lockfile = Bundler::LockfileParser.new(lockfile_contents)
        @spec_by_name = lockfile.specs
          .group_by(&:name) # Faster lookups
          .transform_values(&:first) # Only need one spec per gem
      end

      def search
        results = Result::Group.new

        lockfile.dependencies.keys.each do |gem_name|
          traverse(gem_name, gem_name, Set.new, results)
        end

        results
      end

      def traverse(node, root_node, visited_nodes, results, dependency_chain = [], depth = 0)
        return if depth > MAX_DEPTH
        return if RAILS_COMPONENTS.include?(node)
        return if visited_nodes.include?(node)

        visited_nodes.add(node)

        current_spec = spec_by_name[node] || return
        root_spec = spec_by_name[root_node]
        current_dependency_chain = dependency_chain + ["#{node} (#{current_spec.version})"]

        current_spec.runtime_dependencies.each do |dependency|
          if RAILS_COMPONENTS.include?(dependency.name)
            if !dependency.requirement.satisfied_by?(target_version)
              results.add(
                Result::Conflict.new(
                  direct_dependency: root_spec.name,
                  direct_dependency_version: root_spec.version.to_s,
                  blocking_dependency: current_spec.name,
                  blocking_dependency_version: current_spec.version.to_s,
                  target_dependency: dependency.name,
                  target_dependency_version: target_version.to_s,
                  target_dependency_requirement: dependency.requirement.to_s,
                  dependency_chain: current_dependency_chain.join(" -> ")
                )
              )
            end
          end

          traverse(dependency.name, root_node, visited_nodes, results, current_dependency_chain, depth + 1)
        end
      end

      private

      attr_reader :spec_by_name
    end
  end
end
