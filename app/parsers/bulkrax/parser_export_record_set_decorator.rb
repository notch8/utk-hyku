# frozen_string_literal: true

# OVERRIDE Bulkrax v9.0.2 to account for child works since UTK has the Attachment layer

module Bulkrax
  module ParserExportRecordSetDecorator
    module BaseDecorator
      private

        def works
          @works ||= begin
            @works = Bulkrax.object_factory.query(works_query, **works_query_kwargs)
            child_works = []
            @works.each do |parent_work|
              member_ids = parent_work['member_ids_ssim']
              next unless member_ids

              member_ids.each do |id|
                child_work = Hyrax::SolrService.query("id:#{id}", row: 1, fl: "id,member_ids_ssim")
                child_works += child_work
              end
            end

            @works += child_works
          end
        end
    end
  end
end

Bulkrax::ParserExportRecordSet::Base.prepend(Bulkrax::ParserExportRecordSetDecorator::BaseDecorator)
