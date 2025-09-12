# frozen_string_literal: true

# Override Hyrax 3.4.1 to delete Attachments like FileSets
module Hyrax
  module Actors
    module CleanupFileSetsActorDecorator
      private

        def cleanup_file_sets(curation_concern)
          begin
            file_sets = curation_concern.file_sets
          rescue ActiveFedora::ObjectNotFoundError
            return
          end

          attachments = curation_concern.members
                                        .select { |member| member.is_a? Attachment }
                                        .select { |attachment| attachment.member_of.size == 1 }
          begin
            curation_concern.list_source.destroy
          rescue Ldp::Gone
            Rails.logger.warn "Attempted to access deleted resource: #{curation_concern.id}"
          end

          if attachments.size.positive?
            attachments.each do |attachment|
              cleanup_file_sets(attachment)
              attachment.destroy(eradicate: true)
            end
          end
          Hyrax::SolrService.delete(curation_concern.id)

          return unless file_sets.size.positive?

          file_sets.each do |file_set|
            file_set.delete(eradicate: true)
          end
        end
    end
  end
end

Hyrax::Actors::CleanupFileSetsActor.prepend(Hyrax::Actors::CleanupFileSetsActorDecorator)
