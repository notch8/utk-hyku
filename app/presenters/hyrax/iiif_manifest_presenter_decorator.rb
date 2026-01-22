# frozen_string_literal: true

# OVERRIDE Hyrax 3.4.0 to check the site's ssl_configured when setting protocols
# overriding #display_image to get correct format:
module Hyrax
  module IiifManifestPresenterDecorator
    attr_writer :iiif_version

    ##
    # @return [Array<#to_s>]
    def member_ids
      case model
      when Valkyrie::Resource
        Array(model.try(:member_ids))
      else
        return @member_item_list_ids if @member_item_list_ids.present?
        ordered_ids = Hyrax::SolrDocument::OrderedMembers.decorate(model).ordered_member_ids
        docs = Hyrax::SolrService
               .query("id:(#{ordered_ids.join(' ')})", rows: 2_000_000, method: :post)
               .map { |hit| ::SolrDocument.new(hit) }
        new_order = docs.sort_by do |item|
          if item['sequence_ssm'].present?
            item.sequence_number
          else
            ordered_ids.index(item.id)
          end
        end
        @member_item_list_ids = new_order.map(&:id)
      end
    end

    def iiif_version
      @iiif_version || 3
    end

    def search_service
      url = Rails.application.routes.url_helpers.solr_document_iiif_search_url(id, host: hostname)
      Site.account.ssl_configured ? url.sub(/\Ahttp:/, 'https:') : url
    end

    ##
    # @return [String] the URL where the manifest can be found
    def manifest_url
      return '' if id.blank?

      Rails.application.routes.url_helpers.polymorphic_url([:manifest, model], host: hostname, protocol: protocol)
    end

    ##
    # @return [String] the URL that is used in the manifest to link back to the show page
    # @see ManifestBuilderServiceDecorator#homepage
    def work_url
      Rails.application.routes.url_helpers.polymorphic_url(model, host: hostname, protocol: protocol)
    end

    # TODO: MAY BE A TEMPORARY IMPLEMENTATION UNTIL #is_part_of IS SET UP
    ##
    # @return [String] the URL to the Work's Collection show page
    def collection_url(collection_id)
      return '' if collection_id.blank?

      "#{protocol}://#{hostname}/collections/#{collection_id}"
    end

    module DisplayImagePresenterDecorator
      # overriding to include #display_content from the hyrax-iiif_av gem
      def display_image; end
      include Hyrax::IiifAv::DisplaysContent

      # override Hyrax to keep pdfs from gumming up the v3 manifest
      # in app/presenters/hyrax/iiif_manifest_presenter.rb
      def file_set?
        super && (image? || audio? || video?) && intermediate_file?
      end

      # OVERRIDE Hyrax 3.5.0 to use #supplementing_content for IIIF Manifest v1.3.1
      def supplementing_content
        @supplementing_content ||= begin
                                     return [] unless media_and_transcript?

                                     attachment_docs = transcript_attachments
                                     attachment_docs.map do |doc|
                                       create_supplementing_content(doc)
                                     end
                                   end
      end

      private

        TRANSCRIPT_RDF_TYPE = "http://pcdm.org/use#Transcript"

        def media_and_transcript?
          (audio? || video?) && transcript_attachments.present?
        end

        def transcript_attachments
          member_ids = Hyrax::SolrService.query(
            "file_set_ids_ssim:#{id} AND -has_model_ssim:Attachment", rows: count, fl: 'id,member_ids_ssim'
          ).first['member_ids_ssim']

          return [] unless member_ids
          Hyrax::SolrService.query(
            "id:(#{member_ids.join(' OR ')})",
            rows: member_ids.length,
            fl: 'id,title_tesim,file_language_ssm,rdf_type_ssm,member_ids_ssim'
          ).select { |hit| hit['rdf_type_ssm'].present? && hit['rdf_type_ssm'].include?(TRANSCRIPT_RDF_TYPE) }
        end

        def create_supplementing_content(attachment)
          hash = get_file_set_ids_and_languages(attachment)

          captions_url = Rails.application.routes.url_helpers.supplementing_content_url(
            id: hash[:file_set_id], protocol: 'https'
          )

          IIIFManifest::V3::SupplementingContent.new(
            captions_url,
            type: 'Text',
            format: 'text/vtt',
            label: hash[:title],
            language: hash[:language] || 'en'
          )
        end

        def get_file_set_ids_and_languages(doc)
          {
            file_set_id: doc['member_ids_ssim']&.first,
            title: doc['title_tesim']&.first,
            language: doc['file_language_ssm']&.first
          }
        end

        def get_captions_url(file_set_id)
          captions_url = Hyrax::Engine.routes.url_helpers.download_url(file_set_id, host: hostname)
          ssl_configured = Site.account.ssl_configured
          ssl_configured ? captions_url.sub!(/\Ahttp:/, 'https:') : captions_url
        end
    end

    private

      def scrub(value)
        CGI.unescapeHTML(Loofah.fragment(value).scrub!(:whitewash).to_s)
      end

      def protocol
        @protocol ||= @base_url.start_with?('https') ? 'https' : 'http'
      end
  end
end

Hyrax::IiifManifestPresenter.prepend(Hyrax::IiifManifestPresenterDecorator)
Hyrax::IiifManifestPresenter::DisplayImagePresenter
  .prepend(Hyrax::IiifManifestPresenterDecorator::DisplayImagePresenterDecorator)
