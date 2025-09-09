# frozen_string_literal: true

# OVERRIDE
module Bulkrax
  module FileSetEntryBehaviorDecorator
    # If the object already exists, this is an object update
    def update?
      factory.find.present?
    end

    # Do no raise an error if this is an update
    def validate_presence_of_filename!
      return if parsed_metadata&.[](file_reference)&.map(&:present?)&.any?

      raise StandardError, 'File set must have a filename' unless update?
    end
  end
end

Bulkrax::FileSetEntryBehavior.prepend(Bulkrax::FileSetEntryBehaviorDecorator)
