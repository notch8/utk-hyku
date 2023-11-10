# frozen_string_literal: true

class AppIndexer < Hyrax::WorkIndexer
  # This indexes the default metadata. You can remove it if you want to
  # provide your own metadata and indexing.
  # include Hyrax::IndexesBasicMetadata

  # Fetch remote labels for objects with controlled properties (i.e. :based_near)
  # Utk does not include based_near and does not need deep indexing.
  # include Hyrax::IndexesLinkedMetadata

  # Uncomment this block if you want to add custom indexing behavior:
  def generate_solr_document
    super.tap do |solr_doc|
      solr_doc["account_cname_tesim"] = Site.instance&.account&.cname
      solr_doc["bulkrax_identifier_ssim"] = object.bulkrax_identifier
      # tesim is the wrong field for this, but until we reindex everything we need to keep it
      solr_doc["bulkrax_identifier_tesim"] = object.bulkrax_identifier
      solr_doc[CatalogController.title_field] = object.title.first
    end
  end
end
