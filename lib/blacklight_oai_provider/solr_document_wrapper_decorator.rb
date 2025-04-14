# frozen_string_literal: true

# OVERRIDE Blacklight OAI Provider v6.1.1 to filter out unwanted work types

module BlacklightOaiProvider
  module SolrDocumentWrapperDecorator
    private

      def conditions(_options)
        query = super

        # Add our filter to exclude what we want to exclude from catalog search
        # according to IIIF Print's configuration
        IiifPrint.config.excluded_model_name_solr_field_values.each do |model|
          query.append_filter_query("-has_model_ssim:#{model}")
        end

        query
      end
  end
end

BlacklightOaiProvider::SolrDocumentWrapper.prepend(BlacklightOaiProvider::SolrDocumentWrapperDecorator)
