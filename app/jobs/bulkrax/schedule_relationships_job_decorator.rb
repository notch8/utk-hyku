# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 to alter the query so we kick off the relationship jobs at the correct time

module Bulkrax
  module ScheduleRelationshipsJobDecorator
    def perform(importer_id:)
      importer = Importer.find(importer_id)

      processed_entries =
        Bulkrax::Status
        .where(statusable_id: importer.entries.pluck(:id))
        .where(runnable_id: importer.last_run.id)
        .where(status_message: ['Complete', 'Failed', 'Skipped'])
        .pluck(:statusable_id).uniq
      pending_entries = importer.entries.where.not(id: processed_entries)
      pending_num = pending_entries.count

      return reschedule(importer_id) unless pending_num.zero?

      importer.last_run.parents.each do |parent_id|
        Bulkrax.relationship_job_class.constantize.perform_later(parent_identifier: parent_id,
                                                                 importer_run_id: importer.last_run.id)
      end
    end
  end
end

Bulkrax::ScheduleRelationshipsJob.prepend(Bulkrax::ScheduleRelationshipsJobDecorator)
