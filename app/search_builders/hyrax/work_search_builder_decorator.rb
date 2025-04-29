# frozen_string_literal: true

# OVERRIDE Hyrax v3.6.0 to allow users with access to a collection to view works in that collection

Hyrax::WorkSearchBuilder.include(Hyrax::CollectionAwareSingleResult)
