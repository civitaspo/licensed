# frozen_string_literal: true

module Licensed
  module Sources
    class Source
      class DependencyEnumerationNotImplementedError < StandardError
        def initialize(message = "Source classes must implemented `enumerate_dependencies`")
          super
        end
      end

      class Error < StandardError; end

      class << self
        attr_reader :sources
        def inherited(klass)
          # add child source classes are defined,
          # add them to the known sources list
          (@sources ||= []) << klass
        end

        # Returns the source name as the first snake cased class or module name
        # following "Licensed::Sources::".  This is the type that is included
        # in metadata files and cache paths.
        # e.g. for `Licensed::Sources::Yarn::V1`, this returns "yarn"
        def type
          type_and_version[0]
        end

        # Returns the source name as a "/" delimited string of all the module and
        # class names following "Licensed::Sources::".  This is the type that is
        # used to distinguish multiple versions of a sources from each other.
        # e.g. for `Licensed::Sources::Yarn::V1`, this returns `yarn/v1`
        def full_type
          type_and_version.join("/")
        end

        # Returns an array that includes the source's type name at the first index, and
        # optionally a version string for the source as the second index.
        # Callers should override this function and not `type` or `full_type` when
        # needing to adjust the default type and version parsing logic
        def type_and_version
          self.name.gsub("#{Licensed::Sources.name}::", "")
                   .gsub(/([A-Z\d]+)([A-Z][a-z])/, "\\1_\\2".freeze)
                   .gsub(/([a-z\d])([A-Z])/, "\\1_\\2".freeze)
                   .downcase
                   .split("::")
        end
      end

      # all sources have a configuration
      attr_accessor :config

      def initialize(configuration)
        @config = configuration
      end

      # Returns whether a source is enabled based on the environment in which licensed is run
      # Defaults to false.
      def enabled?
        false
      end

      # Returns all dependencies that should be evaluated.
      # Excludes ignored dependencies.
      def dependencies
        cached_dependencies.reject { |d| ignored?(d) }
      end

      # Enumerate all source dependencies.  Must be implemented by each source class.
      def enumerate_dependencies
        raise DependencyEnumerationNotImplementedError
      end

      # Returns whether a dependency is ignored in the configuration.
      def ignored?(dependency)
        config.ignored?("type" => self.class.type, "name" => dependency.name)
      end

      private

      # Returns a cached list of dependencies
      def cached_dependencies
        @dependencies ||= enumerate_dependencies.compact
      end
    end
  end
end
