# frozen_string_literal: true

module Hyrax
  module CollectionAwareSingleResult
    extend ActiveSupport::Concern

    included do
      self.default_processor_chain += [:apply_collection_viewer_access]
    end

    def apply_collection_viewer_access(solr_parameters)
      return if current_user.blank? || current_user.admin?

      work_id = blacklight_params[:id]
      return if work_id.blank?

      # find which collections this work belongs to
      work_query = "id:#{work_id}"
      work_doc = Hyrax::SolrService.query(work_query, fl: 'member_of_collection_ids_ssim', rows: 1).first
      return if work_doc.blank?

      collection_ids = work_doc['member_of_collection_ids_ssim']
      return if collection_ids.blank?

      collection_access = collection_ids.any? do |coll_id|
        # check if user has access to this collection
        read_access_person = "read_access_person_ssim:#{current_user.user_key}"
        collection_query = "id:#{coll_id} AND (#{read_access_person})"

        Hyrax::SolrService.count(collection_query).positive?
      end

      return unless collection_access
      # find and remove any access filters since the user has access to the collection
      current_access_filters = solr_parameters[:fq].select { |fq| fq.include?('_access_') }
      current_access_filters.each { |filter| solr_parameters[:fq].delete(filter) }
    end
  end
end
