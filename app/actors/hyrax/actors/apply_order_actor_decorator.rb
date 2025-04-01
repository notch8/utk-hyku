# frozen_string_literal: true

# OVERRIDE Hyrax v3.6.0 to remove nils from :ordered_member_ids
# TODO: Why were nils in ordered_member_ids?  I had one locally but after using this to save, it cleared itself up.

module Hyrax
  module Actors
    module ApplyOrderActorDecorator
      def cleanup_ids_to_remove_from_curation_concern(curation_concern, ordered_member_ids)
        (curation_concern.ordered_member_ids.compact - ordered_member_ids).each do |old_id|
          # rubocop:disable Rails/DynamicFindBy
          work = Hyrax.query_service.find_by_alternate_identifier(alternate_identifier: old_id, use_valkyrie: false)
          # rubocop:enable Rails/DynamicFindBy
          curation_concern.ordered_members.delete(work)
          curation_concern.members.delete(work)
        end
      end
    end
  end
end

Hyrax::Actors::ApplyOrderActor.prepend(Hyrax::Actors::ApplyOrderActorDecorator)
