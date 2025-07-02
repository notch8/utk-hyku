# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include BlacklightRangeLimit::RangeLimitBuilder

  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  def add_access_controls_to_solr_params(solr_parameters)
    return if collection_viewer?

    apply_gated_discovery(solr_parameters)
  end

  private

    def collection_viewer?
      user = current_ability.current_user
      return false unless user && user.user_key.present?
      return false if user.admin?

      object_id = blacklight_params[:id]
      return false if object_id.blank?

      collection_ids = find_collection(object_id)
      return false if collection_ids.blank?

      collection_query = collection_ids.map { |id| "id:#{id}" }.join(' OR ')

      Hyrax::SolrService.count("(#{collection_query}) AND read_access_person_ssim:#{user.user_key}").positive?
    end

    def find_collection(object_id)
      doc = find_doc(object_id)

      doc = if doc['has_model_ssim'].first == 'Attachment'
        find_doc(doc['is_page_of_ssim'])
      elsif doc['has_model_ssim'].first == 'FileSet'
        find_doc(doc['is_page_of_ssim'])
      else
        doc
      end

      doc.fetch('member_of_collection_ids_ssim', nil)
    end

    def find_doc(ids)
      id_query = Array.wrap(ids).map { |id| "id:#{id}" }.join(" OR ")

      docs = Hyrax::SolrService.query(
        id_query,
        fl: 'id,has_model_ssim,member_of_collection_ids_ssim,is_page_of_ssim',
        rows: ids.length
      )

      return docs.first if docs.one?

      docs.find { |doc| doc['has_model_ssim'].first != 'Attachment' }
    end
end
