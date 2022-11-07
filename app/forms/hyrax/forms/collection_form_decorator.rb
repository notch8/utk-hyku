# frozen_string_literal: true

module Hyrax
  module Forms
    module CollectionFormDecorator
      # Terms that appear above the accordion
      def primary_terms
        %i[title abstract]
      end

      def secondary_terms
        %i[
          contributor
          creator
          date_created
          date_created_d
          date_issued
          date_issued_d
          extent
          form
          keyword
          note
          publication_place
          publisher
          repository
          resource_type
          spatial
          subject
          utk_contributor
          utk_creator
          utk_publisher
        ]
      end
    end
  end
end

# adds custom terms to `self.terms`
Hyrax::Forms::CollectionForm.terms += %i[
  abstract
  date_created_d
  date_issued
  date_issued_d
  extent
  form
  note
  publication_place
  repository
  spatial
  utk_contributor
  utk_creator
  utk_publisher
]

Hyrax::Forms::CollectionForm.prepend(Hyrax::Forms::CollectionFormDecorator)
