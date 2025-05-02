# frozen_string_literal: true

# OVERRIDE Hyrax v3.6.0 to give users that have view access to the collection to be able to
#   view the works in the collection even if they are private

module Hyrax
  module CollectionMemberSearchBuilderDecorator
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
  .default_processor_chain += %i[member_of_collection apply_viewer_access_permissions]
