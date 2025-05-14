# frozen_string_literal: true

# OVERRIDE Hyrax v3.6.0 so we can set the @child_works_mapper so we can get the search results

module Hyrax
  module CollectionsControllerDecorator
    private

      def member_works
        @response = collection_member_service.available_member_works
        @member_docs = @response.documents
        @members_count = @response.total
        @child_works_mapper = child_works_mapper
      end
      alias load_member_works member_works

      def child_works_mapper
        @member_docs.each_with_object({}) do |parent_doc, hash|
          next if parent_doc['matching_children'].blank?

          hash[parent_doc.id] = parent_doc['matching_children']['docs'].map { |mc| ::SolrDocument.new(mc) }
        end
      end
  end
end

Hyrax::CollectionsController.prepend(Hyrax::CollectionsControllerDecorator)
