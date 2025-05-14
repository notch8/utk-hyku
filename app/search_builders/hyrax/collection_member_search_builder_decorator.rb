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

    def matching_children(solr_parameters)
      user_query = solr_parameters[:user_query]
      return if user_query.blank?

      current_fl = solr_parameters[:fl] || '*'
      solr_parameters[:fl] = "#{current_fl},matching_children:[subquery]"

      solr_parameters['matching_children.q'] = "{!terms f=id v=$row.file_set_ids_ssim} AND #{user_query}"
      solr_parameters['matching_children.fl'] = '*'
      solr_parameters['matching_children.qf'] = solr_parameters[:qf]
      solr_parameters['matching_children.rows'] = 10
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
  .default_processor_chain += %i[apply_viewer_access_permissions matching_children include_allinson_flex_fields]
