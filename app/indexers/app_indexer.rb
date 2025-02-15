# frozen_string_literal: true

class AppIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  # include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for objects with controlled properties (i.e. :based_near)
  # Utk does not include based_near and does not need deep indexing.
  # include Hyrax::IndexesLinkedMetadata

  include AllinsonFlex::DynamicIndexerBehavior

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc["creator_sim"] = convert_uri_to_value(SolrDocument.creator_fields)
      solr_doc["language_sim"] = solr_doc["language_tesim"] = convert_uri_to_value(["language"])
      solr_doc["language_local_sim"] = solr_doc["language_local_tesim"] = convert_uri_to_value(["language"])
      solr_doc["account_cname_tesim"] = Site.instance&.account&.cname
      solr_doc["bulkrax_identifier_ssim"] = object.bulkrax_identifier
      # tesim is the wrong field for this, but until we reindex everything we need to keep it
      solr_doc["bulkrax_identifier_tesim"] = object.bulkrax_identifier
      # using Array() vs Array.wrap() since the objects are ActiveTriples::Relation
      # Array.wrap() will create nested arrays
      solr_doc[CatalogController.title_field] = Array(object.title).first
      solr_doc[CatalogController.published_field] = (
        Array(object.date_issued_d).first if object.respond_to?(:date_issued_d)
      )
      solr_doc[CatalogController.created_field] = (
        Array(object.date_created_d).first if object.respond_to?(:date_created_d)
      )
    end
  end
end
