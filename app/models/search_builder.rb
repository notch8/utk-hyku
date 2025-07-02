# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  # Override Blacklight::AccessControls::Enforcement to allow collection viewers to see collection items
  def add_access_controls_to_solr_params(solr_parameters)
    return if current_ability.current_user.collection_viewer?(blacklight_params[:id])

    apply_gated_discovery(solr_parameters)
  end
end
