# frozen_string_literal: true

# OVERRIDE Hyrax v3.5.0 to index the rdf_type on the FileSet

module Hyrax
  module FileSetIndexerDecorator
    def generate_solr_document
      super.tap do |solr_doc|
        # digest of the original file if we are using an external file due to s3 direct upload
        solr_doc['digest_ssim'] = "urn:sha1:#{object.s3_only}" if object.s3_only.present?
        solr_doc['rdf_type_ssim'] = object.parent_works.first.rdf_type if attachment?
        if solr_doc['rdf_type_ssim']&.first == 'http://pcdm.org/use#Transcript'
          content = object.files.first&.content&.encode('UTF-8', 'binary',
                                                        invalid: :replace,
                                                        undef: :replace,
                                                        replace: '')
          solr_doc['transcript_tsimv'] = content if content
        end
        solr_doc['all_text_tesimv'] = solr_doc['all_text_tsimv'] if solr_doc['all_text_tsimv'].present?
      end
    end

    private

      def attachment?
        object.parent_works.first.is_a?(Attachment)
      end
  end
end

Hyrax::FileSetIndexer.prepend(Hyrax::FileSetIndexerDecorator)
