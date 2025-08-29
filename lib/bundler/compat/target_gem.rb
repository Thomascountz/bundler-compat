# frozen_string_literal: true

module Bundler
  module Compat
    class TargetGem
      # Rails is a special case - it's a meta-gem with multiple components
      RAILS_COMPONENTS = %w[
        actioncable actionmailbox actionmailer actionpack actiontext actionview
        activejob activemodel activerecord activestorage activesupport railties rails
      ].to_set.freeze

      attr_reader :name, :version

      def initialize(name:, version:)
        @name = name.to_s
        @version = Gem::Version.new(version)
        @components = determine_components(name)
      end

      def components?
        !@components.empty?
      end

      def target_gems
        components? ? @components : Set[name]
      end

      def display_name
        components? ? "#{name} (#{@components.size} components)" : name
      end

      private

      def determine_components(gem_name)
        return RAILS_COMPONENTS if gem_name.to_s.downcase == "rails"
        Set.new
      end
    end
  end
end
