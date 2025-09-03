# frozen_string_literal: true

FactoryBot.define do
  factory :bulkrax_csv_entry, class: 'Bulkrax::CsvEntry' do
    identifier { "csv_entry" }
    type { 'Bulkrax::CsvEntry' }
    importerexporter { FactoryBot.build(:bulkrax_importer) }
    raw_metadata { {} }
    parsed_metadata { {} }
  end
end
