# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 to ensure parsed_metadata is set when calling for the name of the class

module Bulkrax
  module FactoryClassFinderDecorator
    def name
      entry.build_metadata if entry.parsed_metadata.blank?

      super
    end
  end
end

Bulkrax::FactoryClassFinder.prepend(Bulkrax::FactoryClassFinderDecorator)
