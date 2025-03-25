# frozen_string_literal: true

# OVERRIDE AllinsonFlex main: c6ec00e to add "title" as a required field
# OVERRIDE AllinsonFlex to add grouped key for the view_properties
module AllinsonFlex
  module DynamicSchemaServiceDecorator
    # OVERRIDE AllinsonFlex main: c6ec00e to add "title" as a required field
    # despite whether it's in the metadata profile due to validations on models
    def required_properties
      ([:title] + property_keys.map { |prop| required_for(prop) }.compact).uniq
    end

    # Pass grouped key to the view used in the attribute_rows partial
    def view_properties
      property_keys.map do |prop|
        { prop => { label: property_locale(prop, 'label'),
                    admin_only: admin_only_for(prop),
                    grouped: grouped_property(prop) } }
      end.inject(:merge)
    end

    def grouped_property(value)
      # UTK uses the mappings -> blacklight field to denote which fields are grouped
      mappings = properties[value][:mappings]
      return false if mappings.blank?

      blacklight_mapping = JSON.parse(mappings.gsub('=>', ':'))['blacklight']
      return false if blacklight_mapping.blank?

      # Only should work on multi valued properties and not the property everything groups into
      #  ex. `creator` also has mappings -> blacklight of `creator_sim`, but we do want to show
      #      this one on the show page.
      blacklight_mapping.ends_with?('_sim') && blacklight_mapping.split('_').first != value.to_s
    end
  end
end

AllinsonFlex::DynamicSchemaService.prepend(AllinsonFlex::DynamicSchemaServiceDecorator)
