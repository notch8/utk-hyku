# frozen_string_literal: true

class CollectionIndexer < Hyrax::CollectionIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  include Hyrax::IndexesBasicMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      converter = UriToStringConverterService.new(object)

      solr_doc["creator_sim"] = solr_doc["creator_tesim"] = converter.convert_uri_to_value(['creator'])
      solr_doc["subject_sim"] = solr_doc["subject_tesim"] = converter.convert_uri_to_value(['subject'])
      solr_doc["contributor_sim"] = solr_doc["contributor_tesim"] = converter.convert_uri_to_value(['contributor'])
      solr_doc["language_sim"] = solr_doc["language_tesim"] = converter.convert_uri_to_value(['language'])
      solr_doc["resource_type_sim"] = solr_doc["resource_type_tesim"] = converter.convert_uri_to_value(['resource_type']) # rubocop:disable Metrics/LineLength
      solr_doc["bulkrax_identifier_sim"] = object.bulkrax_identifier
      solr_doc["account_cname_tesim"] = Site.instance&.account&.cname
      solr_doc[CatalogController.title_field] = Array(object.title).first
      solr_doc[CatalogController.published_field] = Array(object.date_issued_d).first
      solr_doc[CatalogController.created_field] = Array(object.date_created_d).first
      solr_doc["primary_identifier_ssm"] = solr_doc["primary_identifier_tesim"] = object.primary_identifier
    end
  end
end
