# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 03d7e8bf87e52777321ae2d572bd5d221ca40f5c
#          to schedule relationships job when editing and resubmitting a parser as we do with a new parser.
#  TODO: Remove this override when Bulkrax is updated to a version that includes this fix.

module Bulkrax
  module ApplicationParserDecorator
    def rebuild_entries(types_array = nil)
      index = 0
      (types_array || %w[collection work file_set relationship]).each do |type|
        # works are not gurneteed to have Work in the type
        if type.eql?('relationship')
          ScheduleRelationshipsJob.set(wait: 5.minutes).perform_later(importer_id: importerexporter.id)
          next
        end
        importer.entries.where(rebuild_entry_query(type, parser_fields['entry_statuses'])).find_each do |e|
          seen[e.identifier] = true
          e.status_info('Pending', importer.current_run)
          if remove_and_rerun
            delay = calculate_type_delay(type)
            "Bulkrax::DeleteAndImport#{type.camelize}Job"
              .constantize
              .set(wait: delay)
              .send(perform_method, e, current_run)
          else
            "Bulkrax::Import#{type.camelize}Job"
              .constantize
              .send(perform_method, e.id, current_run.id)
          end
          increment_counters(index)
          index += 1
        end
      end
    end
  end
end

Bulkrax::ApplicationParser.prepend(Bulkrax::ApplicationParserDecorator)
