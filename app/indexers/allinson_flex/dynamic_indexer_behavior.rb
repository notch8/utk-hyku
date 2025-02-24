# frozen_string_literal: true

# OVERRIDE AllinsonFlex v0.1.0 to turn URI's into human readable strings
#
# For whatever reason our decorator pattern was not overriding #generate_solr_document
# If you check AllinsonFlex::DynamicIndexerBehavior.ancestors, you get what you expect
# with a decorator.  If you checked the #source_location of :generate_solr_document
# you also get what you expect.  However, when running a reindex, I was not going
# through the decorator.  I decided since this is only one method, overriding the entire
# mixin was acceptable for now.

module AllinsonFlex
  module DynamicIndexerBehavior
    include UriToStringBehavior
    extend ActiveSupport::Concern

    RANGE = "http://www.w3.org/2001/XMLSchema#anyURI"

    included do
      class_attribute :model_class
    end

    def generate_solr_document
      dynamic_schema_service = object.dynamic_schema_service
      uri_properties = uri_properties_from(dynamic_schema_service)

      super.tap do |solr_doc|
        found_mappings = {}

        dynamic_schema_service.indexing_properties.each_pair do |prop_name, index_field_names|
          prop_value = object.send(prop_name)
          value = if uri_properties.include?(prop_name.to_s)
                    string_value = uri_to_value_for(prop_value)
                    found_mappings[prop_name] = string_value if string_value.present?
                  else
                    prop_value
                  end

          index_field_names.each { |index_field_name| solr_doc[index_field_name] = value } if value.present?
        end

        SolrDocument.blacklight_mappings.each do |index_field_name|
          values = convert_uri_to_value(SolrDocument.try("#{index_field_name}_fields"), found_mappings: found_mappings)
          solr_doc["#{index_field_name}_sim"] = solr_doc["#{index_field_name}_tesim"] = values
        end
      end
    end

    private

      def uri_properties_from(dynamic_schema_service)
        schema = HashWithIndifferentAccess.new(dynamic_schema_service.dynamic_schema.schema)
        props_hash = schema[:properties]
        # remove rdf_type since they are also URIs but not for our purposes
        props_hash.keys.select { |k, _v| props_hash[k][:range] == RANGE } - local_authorities - ['rdf_type']
      end

      def local_authorities
        # Hyku has these pluralized while m3 has these singularized, resource type is needed however
        Qa::Authorities::Local.names.map(&:singularize) - ['resource_type']
      end
  end
end
