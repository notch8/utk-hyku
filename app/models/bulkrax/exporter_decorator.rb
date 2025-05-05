# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 because field.mapping only included bulkrax.rb parser_mappings because all other
#   metdata fields are handled in AllinsonFlex.
module Bulkrax
  module ExporterDecorator
    def mapping
      @mapping ||= flex_metadata_mappings.merge(super) || {}
    end

    private

      def flex_metadata_mappings
        ActiveSupport::HashWithIndifferentAccess.new(
          export_properties.map do |m|
            Bulkrax.default_field_mapping.call(m)
          end.inject(:merge)
        )
      end
  end
end

Bulkrax::Exporter.prepend(Bulkrax::ExporterDecorator)
