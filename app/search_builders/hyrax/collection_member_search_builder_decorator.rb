# frozen_string_literal: true

# OVERRIDE Hyrax v3.6.0 to give users that have view access to the collection to be able to
#   view the works in the collection even if they are private

module Hyrax
  module CollectionMemberSearchBuilderDecorator
    include IiifPrint::AllinsonFlexFields
    def member_of_collection(solr_parameters)
      super

      return if solr_parameters[:q].blank?

      original_query = solr_parameters[:q]

      solr_parameters[:user_query] = original_query
      solr_parameters[:defType] = 'lucene'
      solr_parameters[:q] = '{!lucene}' \
                            '_query_:"{!dismax v=$user_query}" ' \
                            '_query_:"{!join from=id to=file_set_ids_ssim}{!dismax v=$user_query}"'
    end

    def apply_viewer_access_permissions(solr_parameters)
      return unless collection
      return unless current_ability.can?(:read, collection)

      current_access_filters = solr_parameters[:fq].select { |fq| fq.include?('_access_') }

      # remove the existing access filters
      current_access_filters.each { |filter| solr_parameters[:fq].delete(filter) }
    end
  end
end

Hyrax::CollectionMemberSearchBuilder.prepend(Hyrax::CollectionMemberSearchBuilderDecorator)
Hyrax::CollectionMemberSearchBuilder
  .default_processor_chain += %i[apply_viewer_access_permissions include_allinson_flex_fields]
