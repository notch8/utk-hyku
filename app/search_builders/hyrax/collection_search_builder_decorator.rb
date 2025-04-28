# frozen_string_literal: true

# OVERRIDE Hyrax v3.6.0 to check the blacklight_params for the sort value

module Hyrax
  module CollectionSearchBuilderDecorator
    def add_sorting_to_solr(solr_parameters)
      return if solr_parameters[:q]
      solr_parameters[:sort] ||= blacklight_params[:sort] || super
    end
  end
end

Hyrax::CollectionSearchBuilder.prepend(Hyrax::CollectionSearchBuilderDecorator)
