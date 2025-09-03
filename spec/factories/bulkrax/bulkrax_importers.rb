# frozen_string_literal: true

FactoryBot.define do
  factory :bulkrax_importer, class: 'Bulkrax::Importer' do
    name { 'CSV Import' }
    admin_set_id { AdminSet.find_or_create_default_admin_set_id }
    user { FactoryBot.build(:base_user) }
    frequency { 'PT0S' }
    parser_klass { 'Bulkrax::CsvParser' }
    limit { 10 }
    parser_fields { { 'import_file_path' => 'spec/fixtures/csv/good.csv' } }
    field_mapping { Bulkrax.config.field_mappings["Bulkrax::CsvParser"]  }
    after :create, &:current_run

    trait :with_relationships_mappings do
      field_mapping do
        {
          'parents' => { 'from' => ['parents_column'], split: /\s*[|]\s*/, related_parents_field_mapping: true },
          'children' => { 'from' => ['children_column'], split: /\s*[|]\s*/, related_children_field_mapping: true }
        }
      end
    end
  end
end
